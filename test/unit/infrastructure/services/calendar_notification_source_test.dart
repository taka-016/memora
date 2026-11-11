import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../queries/calendar/firestore_calendar_watch_query_service_test.mocks.dart' as fs;
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
  MockSpec<GetGroupsWithMembersUsecase>(),
  MockSpec<GetCalendarEventsUsecase>(),
])
void main() {
  test('監視の初回受信と変更受信では全グループの予定を取り直さない', () async {
    final currentMember = MockGetCurrentMemberUseCase();
    final groups = MockGetGroupsWithMembersUsecase();
    final events = MockGetCalendarEventsUsecase();
    const member = MemberDto(id: 'm', displayName: '本人');
    when(currentMember.execute()).thenAnswer((_) async => member);
    when(groups.execute(member)).thenAnswer((_) async => [
      const GroupDto(id: 'g', ownerId: 'm', name: '家族', members: []),
    ]);
    final firestore = fs.MockFirebaseFirestore();
    final collection = fs.MockCollectionReference();
    final query = fs.MockQuery();
    final group = fs.MockDocumentReference();
    final groupDoc = fs.MockDocumentSnapshot();
    when(groupDoc.exists).thenReturn(true);
    final membership = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    final snapshots = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    when(firestore.collection(any)).thenReturn(collection);
    when(collection.where('memberId', isEqualTo: 'm')).thenReturn(query);
    when(collection.where('ownerId', isEqualTo: 'm')).thenReturn(query);
    when(query.snapshots()).thenAnswer((_) => membership.stream);
    when(collection.doc('g')).thenReturn(group);
    when(group.snapshots()).thenAnswer((_) => Stream.value(groupDoc));
    final eventQuery = fs.MockQuery();
    when(collection.where('groupId', isEqualTo: 'g')).thenReturn(eventQuery);
    when(eventQuery.where('endDateTime', isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'))).thenReturn(eventQuery);
    when(eventQuery.where('startDateTime', isLessThan: anyNamed('isLessThan'))).thenReturn(eventQuery);
    when(eventQuery.where('recurrenceRule', isNull: false)).thenReturn(eventQuery);
    when(eventQuery.snapshots()).thenAnswer((_) => snapshots.stream);
    final source = DeviceCalendarNotificationSource(
      currentMember: currentMember, groups: groups, events: events,
      clock: FixedAppClock(DateTime(2026, 11, 10, 15)), firestore: firestore,
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
