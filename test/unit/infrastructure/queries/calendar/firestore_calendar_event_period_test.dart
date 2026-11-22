import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/shared_calendar_cache_providers.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_query_service.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_watch_query_service.dart';

import '../../../../helpers/test_exception.dart';
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
    when(bounded.orderBy('endDateTime')).thenReturn(bounded);
    when(bounded.orderBy('startDateTime')).thenReturn(bounded);
    for (final field in [
      'recurrenceEndDateTime',
      'startDateTime',
      'recurrenceRule',
    ]) {
      when(recurring.orderBy(field)).thenReturn(recurring);
    }
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
    verify(recurring.orderBy('recurrenceEndDateTime')).called(1);
    verify(bounded.orderBy('endDateTime')).called(1);
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
    when(query.orderBy('originalEndDateTime')).thenReturn(query);
    when(query.orderBy('originalStartDateTime')).thenReturn(query);
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
    verify(query.orderBy('originalEndDateTime')).called(1);
    verify(query.get()).called(1);
    verifyNever(cancellations.doc(any));
  });

  for (final upperLimit in [false, true]) {
    test('Firestoreの日時の${upperLimit ? '上限' : '下限'}をまたぐ期間も予定と取消を取得する', () async {
      final period = upperLimit
          ? CalendarEventPeriod.forQuarter(DateTime(9999, 10))
          : CalendarEventPeriod(
              from: DateTime.utc(0, 12, 31, 15),
              to: DateTime.utc(1, 4),
            );
      final from = Timestamp.fromDate(
        upperLimit ? period.queryFrom : DateTime.utc(1),
      );
      final parent = MockQueryDocumentSnapshot();
      final parents = MockQuerySnapshot();
      when(parent.id).thenReturn('series');
      when(parent.data()).thenReturn({
        'groupId': 'g',
        'labelType': 'group',
        'title': '予定',
        'isAllDay': true,
        'startDateTime': from,
        'endDateTime': from,
        'recurrenceRule': 'FREQ=DAILY',
      });
      when(parents.docs).thenReturn([parent]);
      when(recurring.get()).thenAnswer((_) async => parents);

      final cancellations = MockCollectionReference();
      final overrides = MockQuery();
      when(firestore.collection('calendar_event_overrides'))
          .thenReturn(cancellations);
      when(cancellations.where('eventId', isEqualTo: 'series'))
          .thenReturn(overrides);
      when(overrides.where('groupId', isEqualTo: 'g')).thenReturn(overrides);
      when(overrides.get()).thenAnswer((_) async => empty);

      for (final (source, query, startField, endField) in [
        (base, bounded, 'startDateTime', 'endDateTime'),
        (recurring, recurring, 'startDateTime', 'recurrenceEndDateTime'),
        (overrides, overrides, 'originalStartDateTime', 'originalEndDateTime'),
      ]) {
        when(source.where(endField, isGreaterThanOrEqualTo: from))
            .thenReturn(query);
        when(query.orderBy(endField)).thenReturn(query);
        when(query.orderBy(startField)).thenReturn(query);
        if (!upperLimit) {
          when(
            query.where(
              startField,
              isLessThan: Timestamp.fromDate(period.queryTo),
            ),
          ).thenReturn(query);
        }
      }

      final result = await FirestoreCalendarEventQueryService(
        firestore: firestore,
      ).getCalendarEventsByGroupId('g', period: period);
      expect(result.single.id, 'series');
      verify(bounded.get()).called(1);
      verify(recurring.get()).called(1);
      verify(overrides.get()).called(1);
    });
  }

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
  test('画面の繰り返し親予定は未来分を含めて共有し親予定の取消IDを使う', () async {
    final futurePeriod = CalendarEventPeriod.forQuarter(DateTime(2027, 4));
    final futureNormal = MockQuery();
    final boundedRecurring = MockQuery();
    when(
      base.where(
        'endDateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(futurePeriod.queryFrom),
      ),
    ).thenReturn(futureNormal);
    when(
      futureNormal.where(
        'startDateTime',
        isLessThan: Timestamp.fromDate(futurePeriod.queryTo),
      ),
    ).thenReturn(futureNormal);
    when(futureNormal.orderBy('endDateTime')).thenReturn(futureNormal);
    when(futureNormal.orderBy('startDateTime')).thenReturn(futureNormal);
    for (final range in [period, futurePeriod]) {
      when(
        recurring.where(
          'recurrenceEndDateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(range.queryFrom),
        ),
      ).thenReturn(boundedRecurring);
      when(
        boundedRecurring.where(
          'startDateTime',
          isLessThan: Timestamp.fromDate(range.queryTo),
        ),
      ).thenReturn(boundedRecurring);
    }
    for (final field in [
      'recurrenceEndDateTime',
      'startDateTime',
      'recurrenceRule',
    ]) {
      when(boundedRecurring.orderBy(field)).thenReturn(boundedRecurring);
    }
    when(boundedRecurring.snapshots()).thenAnswer((_) => Stream.value(empty));
    when(bounded.snapshots()).thenAnswer((_) => Stream.value(empty));
    when(futureNormal.snapshots()).thenAnswer((_) => Stream.value(empty));
    final parents =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    when(recurring.snapshots()).thenAnswer((_) => parents.stream);

    final cancelledOn = DateTime.utc(2027, 4, 5);
    final container = ProviderContainer.test(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.online),
        firebaseFirestoreProvider.overrideWithValue(firestore),
        onlineCalendarCacheOwnerProvider.overrideWithValue(() => null),
      ],
    );
    final watcher = container.read(watchCalendarEventsUsecaseProvider)!;
    final firstValues = <List<CalendarEventDto>>[];
    final futureValues = <List<CalendarEventDto>>[];
    final first = watcher.execute('g', period: period).listen(firstValues.add);
    StreamSubscription<List<CalendarEventDto>>? future;
    addTearDown(() async {
      verifyNever(firestore.collection('calendar_event_overrides'));
      await first.cancel();
      await future?.cancel();
      await parents.close();
    });

    MockDocumentChange parentChange(
      String id,
      DateTime start, {
      DocumentChangeType type = DocumentChangeType.added,
      String title = '繰り返し予定',
    }) {
      final doc = MockQueryDocumentSnapshot();
      when(doc.id).thenReturn(id);
      when(doc.data()).thenReturn({
        'groupId': 'g',
        'labelType': 'group',
        'title': title,
        'isAllDay': true,
        'startDateTime': Timestamp.fromDate(start),
        'endDateTime': Timestamp.fromDate(start.add(const Duration(days: 1))),
        'recurrenceEndDateTime': Timestamp.fromDate(DateTime.utc(9999, 12, 31)),
        'recurrenceRule': 'FREQ=DAILY',
        'overrideIds': [
          if (id == 'series') 'series_${cancelledOn.microsecondsSinceEpoch}',
        ],
      });
      final change = MockDocumentChange();
      when(change.doc).thenReturn(doc);
      when(change.type).thenReturn(type);
      return change;
    }

    await Future<void>(() {});
    verify(recurring.snapshots()).called(1);
    verifyNever(boundedRecurring.snapshots());
    final currentStart = DateTime.utc(2026, 1, 1);
    final initial = MockQuerySnapshot();
    final initialChanges = [
      parentChange('series', currentStart),
      parentChange('future', DateTime.utc(2027, 4, 1)),
    ];
    when(initial.docChanges).thenReturn(initialChanges);
    parents.add(initial);
    await Future<void>(() {});
    expect(firstValues.single.map((event) => event.id), ['series']);
    expect(
      firstValues.single.single.overrides.single.originalStartDateTime,
      cancelledOn,
    );
    future = watcher
        .execute('g', period: futurePeriod)
        .listen(futureValues.add);
    await Future<void>(() {});
    verifyNever(recurring.snapshots());
    expect(futureValues.single.map((event) => event.id), ['series', 'future']);
    expect(
      futureValues.single.first.overrides.single.originalStartDateTime,
      cancelledOn,
    );

    final update = MockQuerySnapshot();
    final change = parentChange(
      'series',
      currentStart,
      type: DocumentChangeType.modified,
      title: '変更後',
    );
    when(update.docChanges).thenReturn([change]);
    parents.add(update);
    await Future<void>(() {});
    expect(firstValues.last.single.title, '変更後');
    expect(futureValues.last.first.title, '変更後');
    await first.cancel();
    expect(parents.hasListener, isTrue);
    await future.cancel();
    expect(parents.hasListener, isFalse);
  });
  test('親予定の購読失敗中は単発予定を受信しても再試行できる状態を維持する', () async {
    final normal =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    final parents =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    final restartedParents =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    when(bounded.snapshots()).thenAnswer((_) => normal.stream);
    when(recurring.snapshots()).thenAnswer((_) => parents.stream);
    final service = FirestoreCalendarEventWatchQueryService(
      firestore: firestore,
    );
    final values = <List<CalendarEventDto>>[];
    final errors = <Object>[];
    final subscription = service
        .watchCalendarScreenEvents('g', period: period)
        .listen(values.add, onError: errors.add);
    StreamSubscription<List<CalendarEventDto>>? retry;
    addTearDown(() async {
      await subscription.cancel();
      await retry?.cancel();
      await normal.close();
      await parents.close();
      await restartedParents.close();
    });
    normal.add(empty);
    parents.add(empty);
    await Future<void>(() {});
    expect(values, [isEmpty]);

    final error = TestException('親予定の購読に失敗');
    parents.addError(error);
    await Future<void>(() {});
    expect(errors, [error]);

    final doc = MockQueryDocumentSnapshot();
    when(doc.id).thenReturn('single');
    when(doc.data()).thenReturn({
      'groupId': 'g',
      'labelType': 'group',
      'title': '単発予定',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(DateTime.utc(2026, 11, 12)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2026, 11, 13)),
    });
    final change = MockDocumentChange();
    when(change.type).thenReturn(DocumentChangeType.added);
    when(change.doc).thenReturn(doc);
    final snapshot = MockQuerySnapshot();
    when(snapshot.docChanges).thenReturn([change]);
    normal.add(snapshot);
    await Future<void>(() {});
    expect(values, hasLength(1));

    when(recurring.snapshots()).thenAnswer((_) => restartedParents.stream);
    final retried = <List<CalendarEventDto>>[];
    retry = service
        .watchCalendarScreenEvents('g', period: period)
        .listen(retried.add);
    normal.add(snapshot);
    restartedParents.add(empty);
    await Future<void>(() {});
    expect(values.last.single.id, 'single');
    expect(retried.single.single.id, 'single');
    verify(recurring.snapshots()).called(2);
    expect(parents.hasListener, isFalse);
  });
}
