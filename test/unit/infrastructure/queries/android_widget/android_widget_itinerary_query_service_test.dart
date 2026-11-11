import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/queries/android_widget/firestore_android_widget_itinerary_query_service.dart';
import 'package:memora/infrastructure/queries/android_widget/sqlite_android_widget_itinerary_query_service.dart';

import '../calendar/firestore_calendar_watch_query_service_test.mocks.dart';

void main() {
  test('Firestoreは指定日の旅程と必要な旅行のヘッダーだけ取得し場所詳細を読まない', () async {
    final firestore = MockFirebaseFirestore();
    final items = MockCollectionReference();
    final query = MockQuery();
    final snapshot = MockQuerySnapshot();
    final item = MockQueryDocumentSnapshot();
    final day = DateTime(2026, 5, 24);
    when(item.id).thenReturn('item');
    when(item.data()).thenReturn({
      'tripId': 'trip',
      'name': '移動',
      'startDateTime': Timestamp.fromDate(day.add(const Duration(hours: 9))),
      'locationId': 'place',
    });
    when(snapshot.docs).thenReturn([item]);
    when(firestore.collection('itinerary_items')).thenReturn(items);
    when(items.where('groupId', isEqualTo: 'g')).thenReturn(query);
    when(query.where('startDateTime', isNull: false)).thenReturn(query);
    when(
      query.where(
        'startDateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(day),
      ),
    ).thenReturn(query);
    when(
      query.where(
        'startDateTime',
        isLessThan: Timestamp.fromDate(DateTime(2026, 5, 25)),
      ),
    ).thenReturn(query);
    when(query.orderBy('startDateTime')).thenReturn(query);
    when(query.get()).thenAnswer((_) async => snapshot);
    final trips = MockCollectionReference();
    final reference = MockDocumentReference();
    final parent = MockDocumentSnapshot();
    when(parent.exists).thenReturn(true);
    when(parent.id).thenReturn('trip');
    when(parent.data())
        .thenReturn({'groupId': 'g', 'name': '旅行', 'year': 2020});
    when(firestore.collection('trip_entries')).thenReturn(trips);
    when(trips.doc('trip')).thenReturn(reference);
    when(reference.get()).thenAnswer((_) async => parent);
    final result = await FirestoreAndroidWidgetItineraryQueryService(firestore)
        .getDay('g', day);
    expect(result.single.name, '旅行');
    expect(result.single.itineraryItems!.single.name, '移動');
    expect(result.single.itineraryItems!.single.location, isNull);
    verifyNever(firestore.collection('locations'));
    verify(
      query.where(
        'startDateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(day),
      ),
    ).called(1);
    verify(
      query.where(
        'startDateTime',
        isLessThan: Timestamp.fromDate(DateTime(2026, 5, 25)),
      ),
    ).called(1);
    clearInteractions(query);
    when(query.where('startDateTime', isLessThan: Timestamp.fromDate(day)))
        .thenReturn(query);
    when(query.orderBy('startDateTime', descending: true)).thenReturn(query);
    when(query.limit(1)).thenReturn(query);
    await FirestoreAndroidWidgetItineraryQueryService(firestore)
        .findDate('g', DateTime(2026, 5, 25), before: true);
    verify(query.limit(1)).called(1);
    verify(query.orderBy('startDateTime', descending: true)).called(1);
  });
  test('SQLiteは外側の読み取りトランザクション内で旅程の日付とグループを絞る', () async {
    final db = OfflineDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    for (final group in ['g', 'other']) {
      await db.insertRow('groups', {
        'id': group,
        'owner_id': 'm',
        'name': group,
      });
      await db.insertRow('trip_entries', {
        'id': group,
        'group_id': group,
        'year': 2010,
        'name': group,
      });
    }
    final day = DateTime(2026, 5, 24);
    for (final row in [
      ('past', 'g', DateTime(2010)),
      ('shown', 'g', day),
      ('other-group', 'other', day),
      ('future', 'g', DateTime(2030)),
    ]) {
      await db.insertRow('itinerary_items', {
        'id': row.$1,
        'trip_id': row.$2,
        'name': row.$1,
        'start_date_time': row.$3.microsecondsSinceEpoch,
      });
    }
    final query = SqliteAndroidWidgetItineraryQueryService(db);
    final result = await db.execute(() => query.getDay('g', day));
    expect(result.single.itineraryItems!.single.id, 'shown');
    expect(await query.findDate('g', day, before: false), day);
    expect(await query.findDate('g', day, before: true), DateTime(2010));
  });
}
