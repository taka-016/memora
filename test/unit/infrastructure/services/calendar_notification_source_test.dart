import '../../../helpers/test_exception.dart';

import 'package:memora/core/time/app_clock.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/usecases/calendar/watch_calendar_events_usecase.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../queries/calendar/firestore_calendar_watch_query_service_test.mocks.dart'
    as fs;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/usecases/calendar/get_calendar_events_usecase.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';
import 'package:memora/infrastructure/services/calendar_notification_source.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';

import 'calendar_notification_source_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GetCurrentMemberUseCase>(),
  MockSpec<WatchCalendarEventsUsecase>(),
  MockSpec<AppClock>(),
  MockSpec<GetGroupsWithMembersUsecase>(),
  MockSpec<GetCalendarEventsUsecase>(),
])
void main() {
  test('グループごとの初回取得と失敗からの復旧後に受信済み予定を統合し変更削除を反映する', () async {
    final fixture = _NotificationFixture(ids: ['g', 'other']);
    addTearDown(fixture.dispose);
    await fixture.start();
    CalendarEventDto event(String groupId) => CalendarEventDto(
      id: groupId,
      groupId: groupId,
      title: '予定',
      startDateTime: DateTime(2026, 11, 12),
      endDateTime: DateTime(2026, 11, 13),
      isAllDay: true,
    );
    final first = event('g');
    final second = event('other');
    fixture.eventStreams['g']!.add([first]);
    fixture.eventStreams['other']!.add([second]);
    await fixture.flush();
    expect(await fixture.source.load(), unorderedEquals([first, second]));
    fixture.eventStreams['other']!.addError(TestException('取得失敗'));
    await fixture.flush();
    await expectLater(fixture.source.load(), throwsA(isA<TestException>()));
    fixture.eventStreams['other']!.add([second.copyWith(title: '変更')]);
    fixture.eventStreams['g']!.add([]);
    await fixture.flush();
    expect((await fixture.source.load()).single.title, '変更');
    verifyNever(fixture.events.execute(any, period: anyNamed('period')));
  });

  test('所属取得中に日付が変わっても最新の所属を取得して期間を更新する', () async {
    final fixture = _NotificationFixture();
    addTearDown(fixture.dispose);
    await fixture.start();
    final pending = Completer<List<GroupDto>>();
    when(fixture.groups.execute(any)).thenAnswer((_) => pending.future);
    fixture.membership.add(fs.MockQuerySnapshot());
    await fixture.flush();
    fixture.now = DateTime(2026, 11, 11, 15);
    final result = expectLater(fixture.source.load(), completion(isEmpty));
    await fixture.flush();
    pending.complete([]);
    await result;
  });

  test('複数グループ解除の待機中に確定した所属グループの監視を消さない', () async {
    final fixture = _NotificationFixture(ids: ['g', 'retained']);
    addTearDown(fixture.dispose);
    await fixture.start();
    final cancellation = Completer<void>();
    final cancelling = Completer<void>();
    fixture.eventStreams['g']!.onCancel = () {
      cancelling.complete();
      return cancellation.future;
    };
    fixture.ids = [];
    fixture.membership.add(fs.MockQuerySnapshot());
    await cancelling.future;
    fixture.ids = ['retained'];
    fixture.membership.add(fs.MockQuerySnapshot());
    await fixture.flush();
    cancellation.complete();
    await fixture.flush();
    expect(fixture.eventStreams['retained']!.hasListener, isTrue);
  });

  test('期間更新の解除待機中に脱退したグループの監視を再開しない', () async {
    final fixture = _NotificationFixture();
    addTearDown(fixture.dispose);
    await fixture.start();
    final cancellation = Completer<void>();
    final cancelling = Completer<void>();
    fixture.eventStreams['g']!.onCancel = () {
      cancelling.complete();
      return cancellation.future;
    };
    clearInteractions(fixture.watcher);
    fixture.now = DateTime(2026, 11, 11, 15);
    final loading = fixture.source.load();
    await cancelling.future;
    fixture.ids = [];
    fixture.membership.add(fs.MockQuerySnapshot());
    await fixture.flush();
    cancellation.complete();
    await fixture.flush();
    expect(await loading, isEmpty);
    verifyNever(fixture.watcher.execute('g', period: anyNamed('period')));
  });

  for (final closeDuringUpdate in [false, true]) {
    test('所属監視の遅い解除後に古い取得結果で予定監視を追加しない（終了=$closeDuringUpdate）', () async {
      final fixture = _NotificationFixture();
      addTearDown(fixture.dispose);
      await fixture.start();
      final cancellation = Completer<void>();
      final cancelling = Completer<void>();
      fixture.eventStreams['g']!.onCancel = () {
        cancelling.complete();
        return cancellation.future;
      };
      fixture.ids = ['old'];
      fixture.membership.add(fs.MockQuerySnapshot());
      await cancelling.future;
      if (closeDuringUpdate) {
        await fixture.subscription.cancel();
      } else {
        fixture.ids = ['new'];
        fixture.membership.add(fs.MockQuerySnapshot());
        await fixture.flush();
      }
      cancellation.complete();
      await fixture.flush();
      verifyNever(fixture.watcher.execute('old', period: anyNamed('period')));
      await fixture.dispose();
    });
  }

  test('グループが削除されたら所属文書が残っていても予定監視を解除する', () async {
    final fixture = _NotificationFixture();
    addTearDown(fixture.dispose);
    await fixture.start();
    fixture.groupExists('g', false);
    await fixture.flush();
    expect(fixture.eventStreams['g']!.hasListener, isFalse);
    expect(await fixture.source.load(), isEmpty);
    await fixture.dispose();
  });

  test('監視の初回受信と変更受信では全グループの予定を取り直さない', () async {
    final currentMember = MockGetCurrentMemberUseCase();
    final groups = MockGetGroupsWithMembersUsecase();
    final events = MockGetCalendarEventsUsecase();
    const member = MemberDto(id: 'm', displayName: '本人');
    when(currentMember.execute()).thenAnswer((_) async => member);
    when(groups.execute(member)).thenAnswer(
      (_) async => [
        const GroupDto(id: 'g', ownerId: 'm', name: '家族', members: []),
      ],
    );
    final firestore = fs.MockFirebaseFirestore();
    final collection = fs.MockCollectionReference();
    final query = fs.MockQuery();
    final group = fs.MockDocumentReference();
    final groupDoc = fs.MockDocumentSnapshot();
    when(groupDoc.exists).thenReturn(true);
    final membership =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    final snapshots =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    when(firestore.collection(any)).thenReturn(collection);
    when(collection.where('memberId', isEqualTo: 'm')).thenReturn(query);
    when(collection.where('ownerId', isEqualTo: 'm')).thenReturn(query);
    when(query.snapshots()).thenAnswer((_) => membership.stream);
    when(collection.doc('g')).thenReturn(group);
    when(group.snapshots()).thenAnswer((_) => Stream.value(groupDoc));
    final eventQuery = fs.MockQuery();
    when(collection.where('groupId', isEqualTo: 'g')).thenReturn(eventQuery);
    when(
      eventQuery.where(
        'endDateTime',
        isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'),
      ),
    ).thenReturn(eventQuery);
    when(eventQuery.where('startDateTime', isLessThan: anyNamed('isLessThan')))
        .thenReturn(eventQuery);
    when(eventQuery.where('recurrenceRule', isNull: true))
        .thenReturn(eventQuery);
    when(
      eventQuery.where(
        'recurrenceEndDateTime',
        isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'),
      ),
    ).thenReturn(eventQuery);
    when(eventQuery.where('recurrenceRule', isNull: false))
        .thenReturn(eventQuery);
    when(eventQuery.snapshots()).thenAnswer((_) => snapshots.stream);
    final source = DeviceCalendarNotificationSource(
      currentMember: currentMember,
      groups: groups,
      events: events,
      clock: FixedAppClock(DateTime(2026, 11, 10, 15)),
      firestore: firestore,
    );
    final sub = source.changes().listen((_) {}, onError: (Object _) {});
    await Future<void>(() {});
    membership.add(fs.MockQuerySnapshot());
    await Future<void>(() {});
    final empty = fs.MockQuerySnapshot();
    when(empty.docs).thenReturn([]);
    when(empty.docChanges).thenReturn([]);
    snapshots.add(empty);
    await Future<void>(() {});
    expect(await source.load(), isEmpty);
    snapshots.add(empty);
    await Future<void>(() {});
    expect(await source.load(), isEmpty);
    verifyNever(events.execute(any, period: anyNamed('period')));
    await sub.cancel();
    await membership.close();
    await snapshots.close();
  });

  test('通知用の全所属グループ取得へ現在の通知対象期間を渡す', () async {
    final currentMember = MockGetCurrentMemberUseCase();
    final groups = MockGetGroupsWithMembersUsecase();
    final events = MockGetCalendarEventsUsecase();
    const member = MemberDto(id: 'm', displayName: '本人');
    when(currentMember.execute()).thenAnswer((_) async => member);
    when(groups.execute(member)).thenAnswer(
      (_) async => [
        const GroupDto(id: 'g1', ownerId: 'm', name: '家族', members: []),
        const GroupDto(id: 'g2', ownerId: 'other', name: '友人', members: []),
      ],
    );
    final now = DateTime(2026, 11, 10, 15);
    final source = DeviceCalendarNotificationSource(
      currentMember: currentMember,
      groups: groups,
      events: events,
      clock: FixedAppClock(now),
    );
    await source.load();
    final period = CalendarEventPeriod.forNotifications(now);
    verify(events.execute('g1', period: period)).called(1);
    verify(events.execute('g2', period: period)).called(1);
    verifyNoMoreInteractions(events);
  });
}

class _NotificationFixture {
  _NotificationFixture({this.ids = const ['g']}) {
    const member = MemberDto(id: 'm', displayName: '本人');
    when(current.execute()).thenAnswer((_) async => member);
    when(groups.execute(member)).thenAnswer(
      (_) async => [
        for (final id in ids)
          GroupDto(id: id, ownerId: 'other', name: id, members: []),
      ],
    );
    when(firestore.collection(any)).thenReturn(collection);
    when(collection.where('memberId', isEqualTo: 'm')).thenReturn(query);
    when(collection.where('ownerId', isEqualTo: 'm')).thenReturn(query);
    when(query.snapshots()).thenAnswer((_) => membership.stream);
    when(collection.doc(any)).thenAnswer((invocation) {
      final id = invocation.positionalArguments.single as String;
      final document = fs.MockDocumentReference();
      final stream = groupStreams.putIfAbsent(
        id,
        () =>
            StreamController<
              DocumentSnapshot<Map<String, dynamic>>
            >.broadcast(),
      );
      when(document.snapshots()).thenAnswer((_) => stream.stream);
      return document;
    });
    when(watcher.execute(any, period: anyNamed('period')))
        .thenAnswer((invocation) {
          final id = invocation.positionalArguments.single as String;
          return eventStreams
              .putIfAbsent(id, () => StreamController<List<CalendarEventDto>>())
              .stream;
        });
    when(clock.now()).thenAnswer((_) => now);
    source = DeviceCalendarNotificationSource(
      currentMember: current,
      groups: groups,
      events: events,
      watchEvents: watcher,
      firestore: firestore,
      clock: clock,
    );
  }
  final current = MockGetCurrentMemberUseCase();
  final groups = MockGetGroupsWithMembersUsecase();
  final events = MockGetCalendarEventsUsecase();
  final watcher = MockWatchCalendarEventsUsecase();
  final firestore = fs.MockFirebaseFirestore();
  final collection = fs.MockCollectionReference();
  final query = fs.MockQuery();
  final membership =
      StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
  final groupStreams =
      <String, StreamController<DocumentSnapshot<Map<String, dynamic>>>>{};
  final eventStreams = <String, StreamController<List<CalendarEventDto>>>{};
  List<String> ids;
  var now = DateTime(2026, 11, 10, 15);
  final clock = MockAppClock();
  late DeviceCalendarNotificationSource source;
  late StreamSubscription<void> subscription;
  Future<void> flush() => Future<void>(() {});
  void groupExists(String id, bool exists) {
    final doc = fs.MockDocumentSnapshot();
    when(doc.exists).thenReturn(exists);
    groupStreams[id]!.add(doc);
  }

  Future<void> start() async {
    subscription = source.changes().listen((_) {}, onError: (Object _) {});
    await flush();
    membership.add(fs.MockQuerySnapshot());
    await flush();
    for (final id in ids) {
      groupExists(id, true);
      eventStreams[id]!.add([]);
    }
    await flush();
    await source.load();
  }

  Future<void> dispose() async {
    await subscription.cancel();
    await membership.close();
    for (final stream in groupStreams.values) {
      await stream.close();
    }
    for (final stream in eventStreams.values) {
      await stream.close();
    }
  }
}
