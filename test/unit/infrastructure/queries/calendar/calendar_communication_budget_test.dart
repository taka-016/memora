import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_watch_query_service.dart';

import 'firestore_calendar_watch_query_service_test.mocks.dart';

// SDKの再接続・実バイト数・課金量ではなく、アプリが開始する購読と追加取得を検証する。
void main() {
  Future<void> flush() => Future<void>(() {});

  MockQueryDocumentSnapshot event(String id, {bool recurring = false}) {
    final document = MockQueryDocumentSnapshot();
    when(document.id).thenReturn(id);
    when(document.data()).thenReturn({
      'groupId': 'g',
      'labelType': 'group',
      'title': id,
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(
        recurring ? DateTime.utc(2020) : DateTime.utc(2026, 5, 15),
      ),
      'endDateTime': Timestamp.fromDate(
        recurring ? DateTime.utc(2020, 1, 2) : DateTime.utc(2026, 5, 16),
      ),
      'recurrenceRule': recurring ? 'FREQ=DAILY' : null,
    });
    return document;
  }

  MockQuerySnapshot snapshot(
    List<MockQueryDocumentSnapshot> documents, {
    DocumentChangeType type = DocumentChangeType.added,
  }) {
    final result = MockQuerySnapshot();
    final changes = <DocumentChange<Map<String, dynamic>>>[
      for (final document in documents)
        (() {
          final change = MockDocumentChange();
          when(change.type).thenReturn(type);
          when(change.doc).thenReturn(document);
          return change;
        })(),
    ];
    when(result.docChanges).thenReturn(changes);
    return result;
  }

  for (final recurringUpdate in [false, true]) {
    test(
      '10か月購読中の${recurringUpdate ? '共通系列' : '単発予定'}更新で購読開始・無関係な個別回取得が増加しない',
      () async {
        final firestore = MockFirebaseFirestore();
        final collection = MockCollectionReference();
        final base = MockQuery();
        final normalBase = MockQuery();
        final recurringBase = MockQuery();
        when(firestore.collection('calendar_events')).thenReturn(collection);
        when(collection.where('groupId', isEqualTo: 'g')).thenReturn(base);
        when(base.where('recurrenceRule', isNull: true)).thenReturn(normalBase);
        when(base.where('recurrenceRule', isNull: false))
            .thenReturn(recurringBase);

        final overrides = MockCollectionReference();
        final overrideQuery = MockQuery();
        final empty = MockQuerySnapshot();
        when(empty.docs).thenReturn([]);
        when(firestore.collection('calendar_event_overrides'))
            .thenReturn(overrides);
        when(overrides.where('eventId', isEqualTo: anyNamed('isEqualTo')))
            .thenReturn(overrideQuery);
        when(overrideQuery.where('groupId', isEqualTo: 'g'))
            .thenReturn(overrideQuery);
        when(
          overrideQuery.where(
            'originalEndDateTime',
            isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'),
          ),
        ).thenReturn(overrideQuery);
        when(
          overrideQuery.where(
            'originalStartDateTime',
            isLessThan: anyNamed('isLessThan'),
          ),
        ).thenReturn(overrideQuery);
        when(overrideQuery.orderBy('originalEndDateTime'))
            .thenReturn(overrideQuery);
        when(overrideQuery.orderBy('originalStartDateTime'))
            .thenReturn(overrideQuery);
        when(overrideQuery.get()).thenAnswer((_) async => empty);

        final service = FirestoreCalendarEventWatchQueryService(
          firestore: firestore,
        );
        final periods = [
          for (var month = 1; month <= 10; month++)
            CalendarEventPeriod.forMonth(DateTime(2026, month)),
        ];
        final queries = <MockQuery>[];
        final normalSources =
            <StreamController<QuerySnapshot<Map<String, dynamic>>>>[];
        final recurringSources =
            <StreamController<QuerySnapshot<Map<String, dynamic>>>>[];
        final subscriptions = <StreamSubscription<List<CalendarEventDto>>>[];
        final received = List<int>.filled(10, 0);
        addTearDown(() async {
          for (final subscription in subscriptions) {
            await subscription.cancel();
          }
          for (final source in [...normalSources, ...recurringSources]) {
            expect(source.hasListener, isFalse);
            await source.close();
          }
        });
        for (var index = 0; index < periods.length; index++) {
          final period = periods[index];
          final normal = MockQuery();
          final recurring = MockQuery();
          final normalSource =
              StreamController<QuerySnapshot<Map<String, dynamic>>>();
          final recurringSource =
              StreamController<QuerySnapshot<Map<String, dynamic>>>();
          normalSources.add(normalSource);
          recurringSources.add(recurringSource);
          queries.addAll([normal, recurring]);
          when(
            normalBase.where(
              'endDateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(period.queryFrom),
            ),
          ).thenReturn(normal);
          when(
            recurringBase.where(
              'recurrenceEndDateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(period.queryFrom),
            ),
          ).thenReturn(recurring);
          for (final query in [normal, recurring]) {
            when(
              query.where(
                'startDateTime',
                isLessThan: Timestamp.fromDate(period.queryTo),
              ),
            ).thenReturn(query);
            for (final field in [
              'endDateTime',
              'startDateTime',
              'recurrenceEndDateTime',
              'recurrenceRule',
            ]) {
              when(query.orderBy(field)).thenReturn(query);
            }
          }
          when(normal.snapshots()).thenAnswer((_) => normalSource.stream);
          when(recurring.snapshots()).thenAnswer((_) => recurringSource.stream);
          final bucket = index;
          subscriptions.add(
            service
                .watchCalendarEventsByGroupId('g', period: period)
                .listen((_) => received[bucket]++),
          );
          normalSource.add(snapshot([]));
          recurringSource.add(
            snapshot([
              for (var series = 0; series < 10; series++)
                event('系列$series', recurring: true),
            ]),
          );
        }
        await flush();
        expect(received, everyElement(1));
        // 10か月×10系列。初回に必要な取消情報の取得だけを許容する。
        verify(overrideQuery.get()).called(100);
        for (final query in queries) {
          verify(query.snapshots()).called(1);
        }
        clearInteractions(overrideQuery);

        final affected = <int>[];
        for (var index = 0; index < periods.length; index++) {
          final period = periods[index];
          if (recurringUpdate ||
              (DateTime.utc(2026, 5, 15).isBefore(period.queryTo) &&
                  !DateTime.utc(2026, 5, 16).isBefore(period.queryFrom))) {
            affected.add(index);
            (recurringUpdate ? recurringSources : normalSources)[index].add(
              snapshot(
                [
                  event(
                    recurringUpdate ? '系列0' : '単発',
                    recurring: recurringUpdate,
                  ),
                ],
                type: recurringUpdate
                    ? DocumentChangeType.modified
                    : DocumentChangeType.added,
              ),
            );
          }
        }
        await flush();
        expect(affected, hasLength(recurringUpdate ? 10 : 3));
        for (var index = 0; index < received.length; index++) {
          expect(received[index], affected.contains(index) ? 2 : 1);
        }
        // 単発の追加では0回、共通系列1件の変更では該当する10か月分だけ。
        if (recurringUpdate) {
          verify(overrideQuery.get()).called(10);
        } else {
          verifyNever(overrideQuery.get());
        }
        for (final query in [base, normalBase, recurringBase, ...queries]) {
          verifyNever(query.snapshots());
          verifyNever(query.get());
        }
      },
    );
  }
}
