import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_query_service.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_watch_query_service.dart';

import 'firestore_calendar_watch_query_service_test.mocks.dart';

void main() {
  final period = CalendarEventPeriod(
    from: DateTime.utc(2026, 11, 10),
    to: DateTime.utc(2027, 1, 8),
  );
  late MockFirebaseFirestore firestore;
  late MockQuery base;
  late MockQuery lower;
  late MockQuery bounded;
  late MockQuery recurring;
  late MockQuerySnapshot empty;
  setUp(() {
    firestore = MockFirebaseFirestore();
    final collection = MockCollectionReference();
    base = MockQuery();
    lower = MockQuery();
    bounded = MockQuery();
    recurring = MockQuery();
    empty = MockQuerySnapshot();
    when(firestore.collection('calendar_events')).thenReturn(collection);
    when(collection.where('groupId', isEqualTo: 'g')).thenReturn(base);
    when(
      base.where(
        'endDateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(period.queryFrom),
      ),
    ).thenReturn(lower);
    when(
      lower.where(
        'startDateTime',
        isLessThan: Timestamp.fromDate(period.queryTo),
      ),
    ).thenReturn(bounded);
    when(base.where('recurrenceRule', isNull: true)).thenReturn(base);
    when(base.where('recurrenceRule', isNull: false)).thenReturn(recurring);
    when(
      recurring.where(
        'recurrenceEndDateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(period.queryFrom),
      ),
    ).thenReturn(recurring);
    when(
      recurring.where(
        'startDateTime',
        isLessThan: Timestamp.fromDate(period.queryTo),
      ),
    ).thenReturn(recurring);
    when(empty.docs).thenReturn([]);
    when(empty.docChanges).thenReturn([]);
    when(base.get()).thenAnswer((_) async => empty);
    when(bounded.get()).thenAnswer((_) async => empty);
    when(recurring.get()).thenAnswer((_) async => empty);
  });

  test('期間指定の取得は終了日時と開始日時で絞り過去開始の繰り返しは別に取得する', () async {
    await FirestoreCalendarEventQueryService(firestore: firestore)
        .getCalendarEventsByGroupId('g', period: period);
    verify(base.where('recurrenceRule', isNull: true)).called(1);
    verify(
      recurring.where(
        'recurrenceEndDateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(period.queryFrom),
      ),
    ).called(1);
    verify(bounded.get()).called(1);
    verify(recurring.get()).called(1);
    verifyNever(base.get());
  });

  test('期間内の取消だけを検索し親の個別回IDをたどって過去の取消を取得しない', () async {
    final parent = MockQueryDocumentSnapshot();
    when(parent.id).thenReturn('series');
    when(parent.data()).thenReturn({
      'groupId': 'g',
      'labelType': 'group',
      'title': '予定',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(DateTime.utc(2020)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2020, 1, 4)),
      'recurrenceRule': 'FREQ=DAILY',
      'overrideIds': ['past', 'current', 'future'],
    });
    final parents = MockQuerySnapshot();
    when(parents.docs).thenReturn([parent]);
    when(recurring.get()).thenAnswer((_) async => parents);
    final cancellations = MockCollectionReference();
    final query = MockQuery();
    when(firestore.collection('calendar_event_overrides'))
        .thenReturn(cancellations);
    when(cancellations.where('eventId', isEqualTo: 'series')).thenReturn(query);
    when(query.where('groupId', isEqualTo: 'g')).thenReturn(query);
    when(
      query.where(
        'originalEndDateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(period.queryFrom),
      ),
    ).thenReturn(query);
    when(
      query.where(
        'originalStartDateTime',
        isLessThan: Timestamp.fromDate(period.queryTo),
      ),
    ).thenReturn(query);
    final row = MockQueryDocumentSnapshot();
    final key = DateTime.utc(2026, 11, 8);
    when(row.data()).thenReturn({
      'originalStartDateTime': Timestamp.fromDate(key),
      'isCancelled': true,
    });
    final rows = MockQuerySnapshot();
    when(rows.docs).thenReturn([row]);
    when(query.get()).thenAnswer((_) async => rows);
    final result = await FirestoreCalendarEventQueryService(
      firestore: firestore,
    ).getCalendarEventsByGroupId('g', period: period);
    expect(result.single.overrides.single.originalStartDateTime, key);
    verify(
      query.where(
        'originalEndDateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(period.queryFrom),
      ),
    ).called(1);
    verify(query.get()).called(1);
    verifyNever(cancellations.doc(any));
  });

  test('期間指定の監視も全期間を読まず両方の初回受信を待ち解除時は両方を止める', () async {
    final normalStream =
        StreamController<QuerySnapshot<Map<String, dynamic>>>();
    final recurringStream =
        StreamController<QuerySnapshot<Map<String, dynamic>>>();
    when(bounded.snapshots()).thenAnswer((_) => normalStream.stream);
    when(recurring.snapshots()).thenAnswer((_) => recurringStream.stream);
    when(base.snapshots()).thenAnswer((_) => normalStream.stream);
    final values = <List<dynamic>>[];
    final subscription = FirestoreCalendarEventWatchQueryService(
      firestore: firestore,
    ).watchCalendarEventsByGroupId('g', period: period).listen(values.add);
    addTearDown(() async {
      await subscription.cancel();
      await normalStream.close();
      await recurringStream.close();
    });
    normalStream.add(empty);
    await Future<void>(() {});
    expect(values, isEmpty);
    recurringStream.add(empty);
    await Future<void>(() {});
    expect(values, [isEmpty]);
    verifyNever(base.snapshots());
    await subscription.cancel();
    expect(normalStream.hasListener, isFalse);
    expect(recurringStream.hasListener, isFalse);
  });
}
