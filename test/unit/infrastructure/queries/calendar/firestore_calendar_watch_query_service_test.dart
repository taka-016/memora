import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/infrastructure/services/shared_calendar_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_watch_query_service.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_label_watch_query_service.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_calendar_watch_query_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<Query<Map<String, dynamic>>>(),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<DocumentChange<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
])
void main() {
  late MockFirebaseFirestore firestore;
  late MockCollectionReference collection;
  late MockQuery query;
  late MockQuery cancellationQuery;
  late Future<List<Map<String, dynamic>>> Function() cancellationRows;
  late StreamController<QuerySnapshot<Map<String, dynamic>>> source;
  Future<void> flush() => Future<void>(() {});
  MockQueryDocumentSnapshot doc(
    String id, {
    String title = '予定',
    List<String> ids = const [],
  }) {
    final doc = MockQueryDocumentSnapshot();
    when(doc.id).thenReturn(id);
    when(doc.data()).thenReturn({
      'groupId': 'g',
      'title': title,
      'labelId': 'l',
      'labelType': 'custom',
      'textColor': '#FFFFFF',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
      'overrideIds': ids,
      'recurrenceRule': ids.isEmpty ? null : 'FREQ=DAILY',
      'name': title,
      'color': '#123ABC',
      'sortOrder': id == 'b' ? 0 : 1,
    });
    return doc;
  }

  void emit(
    List<MockQueryDocumentSnapshot> docs,
    List<(DocumentChangeType, MockQueryDocumentSnapshot)> changes,
  ) {
    final snapshot = MockQuerySnapshot();
    when(snapshot.docs).thenReturn(docs);
    final docChanges = <DocumentChange<Map<String, dynamic>>>[
      for (final (type, doc) in changes)
        (() {
          final change = MockDocumentChange();
          when(change.type).thenReturn(type);
          when(change.doc).thenReturn(doc);
          return change;
        })(),
    ];
    when(snapshot.docChanges).thenReturn(docChanges);
    source.add(snapshot);
  }

  setUp(() {
    firestore = MockFirebaseFirestore();
    collection = MockCollectionReference();
    query = MockQuery();
    source = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    when(firestore.collection(any)).thenReturn(collection);
    when(collection.where('groupId', isEqualTo: 'g')).thenReturn(query);
    when(query.snapshots()).thenAnswer((_) => source.stream);
    cancellationQuery = MockQuery();
    cancellationRows = () async => [];
    final cancellations = MockCollectionReference();
    when(firestore.collection('calendar_event_overrides'))
        .thenReturn(cancellations);
    when(cancellations.where('eventId', isEqualTo: anyNamed('isEqualTo')))
        .thenReturn(cancellationQuery);
    when(cancellationQuery.where('groupId', isEqualTo: 'g'))
        .thenReturn(cancellationQuery);
    when(cancellationQuery.get()).thenAnswer((_) async {
      final rows = await cancellationRows();
      final result = MockQuerySnapshot();
      final documents = [
        for (final row in rows)
          (() {
            final value = MockQueryDocumentSnapshot();
            when(value.data()).thenReturn(row);
            return value;
          })(),
      ];
      when(result.docs).thenReturn(documents);
      return result;
    });
    addTearDown(source.close);
  });
  test('端末の共有キャッシュを先に表示し、サーバー確認済みの空期間で上書きする', () async {
    final directory = await Directory.systemTemp.createTemp('calendar-watch-');
    addTearDown(() => directory.delete(recursive: true));
    final cache = SharedCalendarCache(directory: () async => directory);
    final period = CalendarEventPeriod.forQuarter(DateTime(2026, 11));
    const groupId = 'g';
    const ownerId = 'online:a';
    final saved = CalendarEventDto(
      id: 'widget',
      groupId: groupId,
      title: 'ウィジェットで取得した予定',
      startDateTime: DateTime.utc(2026, 11, 1),
      endDateTime: DateTime.utc(2026, 11, 2),
      isAllDay: true,
    );
    await cache.saveEvents(ownerId, groupId, period, [saved]);

    final recurring = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    addTearDown(recurring.close);
    final recurringQuery = MockQuery();
    when(query.where('recurrenceRule', isNull: true)).thenReturn(query);
    when(query.where('recurrenceRule', isNull: false))
        .thenReturn(recurringQuery);
    when(
      query.where(
        'endDateTime',
        isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'),
      ),
    ).thenReturn(query);
    when(query.where('startDateTime', isLessThan: anyNamed('isLessThan')))
        .thenReturn(query);
    when(query.orderBy('endDateTime')).thenReturn(query);
    when(query.orderBy('startDateTime')).thenReturn(query);
    when(query.snapshots(includeMetadataChanges: true))
        .thenAnswer((_) => source.stream);
    when(recurringQuery.snapshots(includeMetadataChanges: true))
        .thenAnswer((_) => recurring.stream);

    MockQuerySnapshot empty({required bool isFromCache}) {
      final snapshot = MockQuerySnapshot();
      when(snapshot.docChanges).thenReturn([]);
      when(snapshot.metadata).thenReturn(_Metadata(isFromCache: isFromCache));
      return snapshot;
    }

    final service = FirestoreCalendarEventWatchQueryService(
      firestore: firestore,
      sharedCache: cache,
      currentOwnerId: () => ownerId,
    );
    final stream = StreamIterator(
      service.watchCalendarScreenEvents(groupId, period: period),
    );
    addTearDown(stream.cancel);
    expect(await stream.moveNext(), isTrue);
    expect(stream.current, [saved]);

    final next = stream.moveNext();
    source.add(empty(isFromCache: true));
    recurring.add(empty(isFromCache: true));
    await flush();
    expect(await cache.loadEvents(ownerId, groupId, period), [saved]);

    source.add(empty(isFromCache: false));
    recurring.add(empty(isFromCache: false));
    expect(await next, isTrue);
    expect(stream.current, isEmpty);
    final updated = await cache.loadEvents(ownerId, groupId, period);
    expect(updated, isEmpty);
  });

  test('一部の月だけ購読しても、別の月に追加された取消を未取得として扱う', () async {
    final directory = await Directory.systemTemp.createTemp('calendar-watch-');
    addTearDown(() => directory.delete(recursive: true));
    final cache = SharedCalendarCache(directory: () async => directory);
    final quarter = CalendarEventPeriod.forQuarter(DateTime(2026, 10));
    final october = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 10));
    final november = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 11));
    final december = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 12));
    const owner = 'online:a';
    final parent = CalendarEventDto(
      id: 'series',
      groupId: 'g',
      title: '変更前',
      startDateTime: DateTime.utc(2026, 10, 2),
      endDateTime: DateTime.utc(2026, 10, 3),
      isAllDay: true,
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=FR',
      version: 1,
    );
    await cache.saveEvents(owner, 'g', quarter, [parent]);

    final recurring = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    addTearDown(recurring.close);
    final recurringQuery = MockQuery();
    when(query.where('recurrenceRule', isNull: true)).thenReturn(query);
    when(query.where('recurrenceRule', isNull: false))
        .thenReturn(recurringQuery);
    for (final (target, start, end) in [
      (query, 'startDateTime', 'endDateTime'),
      (cancellationQuery, 'originalStartDateTime', 'originalEndDateTime'),
    ]) {
      when(
        target.where(
          end,
          isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'),
        ),
      ).thenReturn(target);
      when(target.where(start, isLessThan: anyNamed('isLessThan')))
          .thenReturn(target);
      when(target.orderBy(end)).thenReturn(target);
      when(target.orderBy(start)).thenReturn(target);
    }
    when(query.snapshots(includeMetadataChanges: true))
        .thenAnswer((_) => source.stream);
    when(recurringQuery.snapshots(includeMetadataChanges: true))
        .thenAnswer((_) => recurring.stream);
    final emptyOverrides = MockQuerySnapshot();
    when(emptyOverrides.docs).thenReturn([]);
    when(emptyOverrides.metadata).thenReturn(_Metadata(isFromCache: false));
    when(cancellationQuery.get()).thenAnswer((_) async => emptyOverrides);

    final document = MockQueryDocumentSnapshot();
    final cancelledStart = DateTime.utc(2026, 12, 4);
    when(document.id).thenReturn(parent.id);
    when(document.data()).thenReturn({
      'groupId': 'g',
      'title': '変更後',
      'labelType': 'group',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(parent.startDateTime),
      'endDateTime': Timestamp.fromDate(parent.endDateTime),
      'recurrenceEndDateTime': Timestamp.fromDate(DateTime.utc(9999, 12, 31)),
      'recurrenceRule': parent.recurrenceRule,
      'version': 3,
      'overrideIds': ['series_${cancelledStart.microsecondsSinceEpoch}'],
    });
    final added = MockDocumentChange();
    when(added.type).thenReturn(DocumentChangeType.added);
    when(added.doc).thenReturn(document);
    final singles = MockQuerySnapshot();
    when(singles.docChanges).thenReturn([]);
    when(singles.metadata).thenReturn(_Metadata(isFromCache: false));
    final parents = MockQuerySnapshot();
    when(parents.docChanges).thenReturn([added]);
    when(parents.metadata).thenReturn(_Metadata(isFromCache: false));

    final service = FirestoreCalendarEventWatchQueryService(
      firestore: firestore,
      sharedCache: cache,
      currentOwnerId: () => owner,
    );
    final stream = StreamIterator(
      service.watchCalendarScreenEvents('g', period: october),
    );
    addTearDown(stream.cancel);
    expect(await stream.moveNext(), isTrue);
    final live = stream.moveNext();
    source.add(singles);
    recurring.add(parents);
    expect(await live, isTrue);
    final updated = stream.current.single;
    expect(updated.title, '変更後');
    expect(await cache.loadEvents(owner, 'g', november), [updated]);
    expect(await cache.loadEvents(owner, 'g', december), isNull);
    expect(await cache.loadEvents(owner, 'g', quarter), isNull);
    verify(cancellationQuery.get()).called(1);
  });

  test('色ラベルも共有キャッシュを先に表示し、サーバー確認済みの結果で更新する', () async {
    final directory = await Directory.systemTemp.createTemp(
      'calendar-label-watch-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final cache = SharedCalendarCache(directory: () async => directory);
    const owner = 'online:a';
    const cached = CalendarLabelDto(
      id: 'old',
      groupId: 'g',
      name: '予定',
      color: '#FFFFFF',
    );
    await cache.saveLabels(owner, 'g', [cached], observedAt: 1);
    when(query.snapshots(includeMetadataChanges: true))
        .thenAnswer((_) => source.stream);
    final service = FirestoreCalendarLabelWatchQueryService(
      firestore: firestore,
      sharedCache: cache,
      currentOwnerId: () => owner,
    );
    final stream = StreamIterator(service.watchCalendarLabelsByGroupId('g'));
    addTearDown(stream.cancel);
    expect(await stream.moveNext(), isTrue);
    expect(stream.current, [cached]);

    final next = stream.moveNext();
    final local = MockQuerySnapshot();
    when(local.docs).thenReturn([]);
    when(local.metadata).thenReturn(_Metadata(isFromCache: true));
    source.add(local);
    final remote = MockQuerySnapshot();
    final newLabel = doc('new');
    when(remote.docs).thenReturn([newLabel]);
    when(remote.metadata).thenReturn(_Metadata(isFromCache: false));
    source.add(remote);
    expect(await next, isTrue);
    expect(stream.current.single.id, 'new');
    expect((await cache.loadLabels(owner, 'g'))?.single.id, 'new');
  });

  test('共有相手の購読が残っていても監視失敗後の再試行で再接続する', () async {
    final service = FirestoreCalendarEventWatchQueryService(
      firestore: firestore,
    );
    final errors = <Object>[];
    final first = service
        .watchCalendarEventsByGroupId('g')
        .listen((_) {}, onError: errors.add);
    source.addError(TestException('通信失敗'));
    await flush();
    expect(errors, hasLength(1));
    await source.close();
    source = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    final values = <List<dynamic>>[];
    final retry = service
        .watchCalendarEventsByGroupId('g')
        .listen(values.add, onError: errors.add);
    final a = doc('a');
    emit([a], [(DocumentChangeType.added, a)]);
    await flush();
    expect(values.single.single.id, 'a');
    await first.cancel();
    // 古い共有先の破棄で新しい共有先を外さない。
    final thirdValues = <List<dynamic>>[];
    final third = service
        .watchCalendarEventsByGroupId('g')
        .listen(thirdValues.add);
    await flush();
    expect(thirdValues.single.single.id, 'a');
    verify(query.snapshots()).called(2);
    await retry.cancel();
    await third.cancel();
  });

  test('同じグループと期間の監視を共有し後からの購読にも受信済み予定を渡す', () async {
    final service = FirestoreCalendarEventWatchQueryService(
      firestore: firestore,
    );
    final first = <List<dynamic>>[];
    final second = <List<dynamic>>[];
    final a = doc('a');
    final sub = service.watchCalendarEventsByGroupId('g').listen(first.add);
    emit([a], [(DocumentChangeType.added, a)]);
    await flush();
    final another = service
        .watchCalendarEventsByGroupId('g')
        .listen(second.add);
    await flush();
    expect(second.single.single.id, 'a');
    verify(query.snapshots()).called(1);
    await sub.cancel();
    emit([], [(DocumentChangeType.removed, a)]);
    await flush();
    expect(second.last, isEmpty);
    await another.cancel();
    expect(source.hasListener, isFalse);
  });

  test('初回と追加変更削除を反映し変更のない予定の個別回は再取得しない', () async {
    cancellationRows = () async => [
      {
        'originalStartDateTime': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
        'isCancelled': true,
      },
    ];
    final values = <List<dynamic>>[];
    final sub = FirestoreCalendarEventWatchQueryService(firestore: firestore)
        .watchCalendarEventsByGroupId('g')
        .listen(values.add);
    addTearDown(sub.cancel);
    final a = doc('a', ids: ['o']);
    final b = doc('b');
    emit([a], [(DocumentChangeType.added, a)]);
    await flush();
    expect(values.last.single.overrides.single.isCancelled, isTrue);
    emit([a, b], [(DocumentChangeType.added, b)]);
    await flush();
    verify(cancellationQuery.get()).called(1);
    final changed = doc('a', title: '変更', ids: ['o']);
    emit([changed, b], [(DocumentChangeType.modified, changed)]);
    await flush();
    expect(values.last.first.title, '変更');
    verify(cancellationQuery.get()).called(1);
    emit([b], [(DocumentChangeType.removed, changed)]);
    await flush();
    expect(values.last.single.id, 'b');
    verify(query.snapshots()).called(1);
  });
  test('個別回取得の前後逆転と削除で古い結果を反映せず解除後も通知しない', () async {
    final pending = Completer<List<Map<String, dynamic>>>();
    cancellationRows = () => pending.future;
    final values = <List<dynamic>>[];
    final sub = FirestoreCalendarEventWatchQueryService(firestore: firestore)
        .watchCalendarEventsByGroupId('g')
        .listen(values.add);
    final old = doc('a', ids: ['o']);
    emit([old], [(DocumentChangeType.added, old)]);
    await flush();
    final newer = doc('a', title: '新しい');
    emit([newer], [(DocumentChangeType.modified, newer)]);
    await flush();
    expect(values.last.single.title, '新しい');
    emit([], [(DocumentChangeType.removed, newer)]);
    await flush();
    pending.complete([
      {
        'originalStartDateTime': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
        'isCancelled': true,
      },
    ]);
    await flush();
    expect(values, hasLength(2));
    expect(values.last, isEmpty);
    await sub.cancel();
    expect(source.hasListener, isFalse);
  });
  test('個別回取得失敗を通知し再購読では個別回も再取得する', () async {
    cancellationRows = () async => throw TestException('取得失敗');
    final service = FirestoreCalendarEventWatchQueryService(
      firestore: firestore,
    );
    final errors = <Object>[];
    final sub = service
        .watchCalendarEventsByGroupId('g')
        .listen((_) {}, onError: errors.add);
    final a = doc('a', ids: ['o']);
    emit([a], [(DocumentChangeType.added, a)]);
    await flush();
    expect(errors, hasLength(1));
    await sub.cancel();
    await source.close();
    source = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    cancellationRows = () async => [
      {
        'originalStartDateTime': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
        'isCancelled': true,
      },
    ];
    final values = <List<dynamic>>[];
    final retry = service.watchCalendarEventsByGroupId('g').listen(values.add);
    addTearDown(retry.cancel);
    emit([a], [(DocumentChangeType.added, a)]);
    await flush();
    expect(values.last.single.overrides, hasLength(1));
    verify(cancellationQuery.get()).called(2);
  });
  test('色ラベルの追加変更削除と順序を反映し監視エラーを通知する', () async {
    final values = <List<dynamic>>[];
    final errors = <Object>[];
    final sub = FirestoreCalendarLabelWatchQueryService(firestore: firestore)
        .watchCalendarLabelsByGroupId('g')
        .listen(values.add, onError: errors.add);
    addTearDown(sub.cancel);
    final a = doc('a');
    final b = doc('b');
    emit([a, b], []);
    await flush();
    expect(values.last.map((v) => v.id), ['b', 'a']);
    final changed = doc('b', title: '変更');
    emit([changed], []);
    await flush();
    expect(values.last.single.name, '変更');
    source.addError(TestException('監視失敗'));
    await flush();
    expect(errors, hasLength(1));
  });
}

class _Metadata extends Fake implements SnapshotMetadata {
  _Metadata({required this.isFromCache});

  @override
  final bool isFromCache;
  @override
  bool get hasPendingWrites => false;
}
