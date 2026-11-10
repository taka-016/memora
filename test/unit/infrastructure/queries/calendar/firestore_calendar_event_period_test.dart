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
    when(base.where('recurrenceRule', isNull: false)).thenReturn(recurring);
    when(empty.docs).thenReturn([]);
    when(empty.docChanges).thenReturn([]);
    when(base.get()).thenAnswer((_) async => empty);
    when(bounded.get()).thenAnswer((_) async => empty);
    when(recurring.get()).thenAnswer((_) async => empty);
  });

  test('期間指定の取得は終了日時と開始日時で絞り過去開始の繰り返しは別に取得する', () async {
    await FirestoreCalendarEventQueryService(firestore: firestore)
        .getCalendarEventsByGroupId('g', period: period);
    verify(bounded.get()).called(1);
    verify(recurring.get()).called(1);
    verifyNever(base.get());
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
