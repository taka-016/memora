import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_exception.dart';
import 'android_widget_providers_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<Query<Map<String, dynamic>>>(),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<AndroidWidgetCacheStorage>(),
])
void main() {
  for (final failTrips in [true, false]) {
      test('保存後更新で${failTrips ? '旅行' : '一部の旅程'}取得が失敗したらキャッシュを書き換えない', () async {
        final firestore = MockFirebaseFirestore();
        final tripsCollection = MockCollectionReference();
        final itemsCollection = MockCollectionReference();
        final trips = MockQuery();
        final items = MockQuery();
        final tripsSnapshot = MockQuerySnapshot();
        final itemsSnapshot = MockQuerySnapshot();
        final storage = MockAndroidWidgetCacheStorage();
        final failure = TestException('取得失敗');
        when(firestore.collection('trip_entries')).thenReturn(tripsCollection);
        when(firestore.collection('itinerary_items')).thenReturn(itemsCollection);
        when(tripsCollection.where('groupId', isEqualTo: 'group')).thenReturn(trips);
        when(itemsCollection.where('tripId', isEqualTo: anyNamed('isEqualTo'))).thenReturn(items);
        when(items.orderBy(any, descending: anyNamed('descending'))).thenReturn(items);
        final tripDocs = List.generate(2, (index) {
          final doc = MockQueryDocumentSnapshot();
          when(doc.id).thenReturn('trip-$index');
          when(doc.data()).thenReturn({'groupId': 'group', 'year': 2026});
          return doc;
        });
        when(tripsSnapshot.docs).thenReturn(tripDocs);
        when(trips.get()).thenAnswer((_) async {
          if (failTrips) throw failure;
          return tripsSnapshot;
        });
        final item = MockQueryDocumentSnapshot();
        when(item.id).thenReturn('item');
        when(item.data()).thenReturn({
          'tripId': 'trip-0', 'name': '取得できた旅程',
          'startDateTime': Timestamp.fromDate(DateTime(2026, 9, 12, 10)),
        });
        when(itemsSnapshot.docs).thenReturn([item]);
        var itemReads = 0;
        when(items.get()).thenAnswer((_) async {
          if (++itemReads == 2) throw failure;
          return itemsSnapshot;
        });
        when(storage.getTargetGroupId()).thenAnswer((_) async => 'group');
        when(storage.loadItineraryCache()).thenAnswer((_) async => AndroidWidgetItineraryCacheDto(
          version: 1, groupId: 'group', selectedItineraryDateId: 'trip-0_2026-09-12',
          lastUpdatedAt: DateTime(2026, 9, 12),
          itineraryDates: [AndroidWidgetItineraryDateCacheDto(
            id: 'trip-0_2026-09-12', tripId: 'trip-0', tripName: '保存済みの旅行',
            tripPeriodLabel: '', dateLabel: '', date: DateTime(2026, 9, 12), itineraryItems: const [],
          )],
        ));
        final container = ProviderContainer(overrides: [
          appModeProvider.overrideWithValue(AppMode.online),
          appClockProvider.overrideWithValue(FixedAppClock(DateTime(2026, 9, 12))),
          firebaseFirestoreProvider.overrideWithValue(firestore),
          androidWidgetCacheStorageProvider.overrideWithValue(storage),
        ]);
        addTearDown(container.dispose);

        await expectLater(container.read(refreshAndroidWidgetItineraryCacheUsecaseProvider)
            .executeForSelectedGroup(), throwsA(same(failure)));
        verifyNever(storage.saveItineraryCache(any));
        verifyNever(storage.saveTargetGroupId(any));
        verify(storage.updateWidget()).called(1);
        if (!failTrips) expect(itemReads, 2);
      });
  }
}
