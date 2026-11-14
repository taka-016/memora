import 'package:memora/application/usecases/android_widget/refresh_android_widget_caches_usecase.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/composition_root/providers/calendar_widget_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_mode.dart';
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
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<Query<Map<String, dynamic>>>(),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<AndroidWidgetCacheStorage>(),
  MockSpec<RefreshAndroidWidgetItineraryCacheUsecase>(),
])
void main() {
  for (final entry in [
    (
      refreshSelectedAndroidWidgetCacheProvider,
      AndroidWidgetKind.values.toSet(),
    ),
    (refreshSelectedCalendarWidgetCacheProvider, {AndroidWidgetKind.calendar}),
    (
      refreshSelectedItineraryWidgetCacheProvider,
      {AndroidWidgetKind.itinerary},
    ),
  ]) {
    for (final installed in <Set<AndroidWidgetKind>>[
      {},
      {AndroidWidgetKind.calendar},
      {AndroidWidgetKind.itinerary},
      AndroidWidgetKind.values.toSet(),
    ]) {
      test('保存後更新${entry.$2}は配置$installedの必要な取得口だけを呼ぶ', () async {
        final storage = MockAndroidWidgetCacheStorage();
        final itinerary = MockRefreshAndroidWidgetItineraryCacheUsecase();
        when(storage.getTargetGroupId()).thenAnswer((_) async => 'group');
        var calendarCalls = 0;
        final container = ProviderContainer(
          overrides: [
            androidWidgetCacheStorageProvider.overrideWithValue(storage),
            loadInstalledAndroidWidgetKindsProvider.overrideWithValue(
              () async => installed,
            ),
            refreshAndroidWidgetItineraryCacheUsecaseProvider.overrideWithValue(
              itinerary,
            ),
            refreshCalendarWidgetProvider.overrideWithValue((
              group,
              date,
            ) async {
              expect(group, 'group');
              expect(date, isNull);
              calendarCalls++;
            }),
          ],
        );
        addTearDown(container.dispose);
        await container.read(entry.$1)();
        final targets = installed.intersection(entry.$2);
        expect(
          calendarCalls,
          targets.contains(AndroidWidgetKind.calendar) ? 1 : 0,
        );
        if (targets.contains(AndroidWidgetKind.itinerary)) {
          verify(
            itinerary.execute(groupId: 'group', selectedItineraryDateId: null),
          ).called(1);
        } else {
          verifyNever(
            itinerary.execute(
              groupId: anyNamed('groupId'),
              selectedItineraryDateId: anyNamed('selectedItineraryDateId'),
            ),
          );
        }
      });
    }
  }

  test('Android以外のカレンダー更新はデータ取得の依存を生成しない', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await expectLater(
      container.read(refreshCalendarWidgetProvider)('group', null),
      completes,
    );
  });

  for (final failTrips in [true, false]) {
    test('保存後更新で${failTrips ? '旅行' : '一部の旅程'}取得が失敗したらキャッシュを書き換えない', () async {
      final firestore = MockFirebaseFirestore();
      final tripsCollection = MockCollectionReference();
      final itemsCollection = MockCollectionReference();
      final items = MockQuery();
      final itemsSnapshot = MockQuerySnapshot();
      final storage = MockAndroidWidgetCacheStorage();
      final failure = TestException('取得失敗');
      final groups = MockCollectionReference();
      final groupRef = MockDocumentReference();
      final groupDoc = MockDocumentSnapshot();
      when(firestore.collection('groups')).thenReturn(groups);
      when(groups.doc('group')).thenReturn(groupRef);
      when(groupRef.get()).thenAnswer((_) async => groupDoc);
      when(groupDoc.exists).thenReturn(true);
      when(firestore.collection('trip_entries')).thenReturn(tripsCollection);
      final tripQuery = MockQuery();
      final tripSnapshot = MockQuerySnapshot();
      final trip = MockQueryDocumentSnapshot();
      when(trip.id).thenReturn('trip-0');
      when(trip.data()).thenReturn({'groupId': 'group', 'name': '旅行'});
      when(tripSnapshot.docs).thenReturn([trip]);
      when(tripsCollection.where('groupId', isEqualTo: 'group'))
          .thenReturn(tripQuery);
      when(tripQuery.get()).thenAnswer((_) async {
        if (failTrips) throw failure;
        return tripSnapshot;
      });
      when(items.where('tripId', isEqualTo: 'trip-0')).thenReturn(items);
      when(items.orderBy('startDateTime', descending: true)).thenReturn(items);

      when(firestore.collection('itinerary_items')).thenReturn(itemsCollection);
      when(itemsCollection.where('groupId', isEqualTo: 'group'))
          .thenReturn(items);
      when(items.where('startDateTime', isNull: false)).thenReturn(items);
      when(
        items.where(
          'startDateTime',
          isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'),
        ),
      ).thenReturn(items);
      when(items.where('startDateTime', isLessThan: anyNamed('isLessThan')))
          .thenReturn(items);
      when(items.orderBy('startDateTime')).thenReturn(items);
      when(items.limit(1)).thenReturn(items);
      final tripRef = MockDocumentReference();
      when(tripsCollection.doc('trip-0')).thenReturn(tripRef);
      when(tripRef.get()).thenAnswer((_) async => throw failure);
      final item = MockQueryDocumentSnapshot();
      when(item.id).thenReturn('item');
      when(item.data()).thenReturn({
        'tripId': 'trip-0',
        'name': '取得できた旅程',
        'startDateTime': Timestamp.fromDate(DateTime(2026, 9, 12, 10)),
      });
      when(itemsSnapshot.docs).thenReturn([item]);
      var itemReads = 0;
      when(items.get()).thenAnswer((_) async {
        if (++itemReads == 2 && !failTrips) throw failure;
        return itemsSnapshot;
      });
      when(storage.getTargetGroupId()).thenAnswer((_) async => 'group');
      final container = ProviderContainer(
        overrides: [
          appModeProvider.overrideWithValue(AppMode.online),
          appClockProvider.overrideWithValue(
            FixedAppClock(DateTime(2026, 9, 12)),
          ),
          firebaseFirestoreProvider.overrideWithValue(firestore),
          androidWidgetCacheStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(refreshAndroidWidgetItineraryCacheUsecaseProvider)
            .executeForSelectedGroup(),
        throwsA(same(failure)),
      );
      verifyNever(storage.saveItineraryCache(any));
      verifyNever(storage.saveTargetGroupId(any));
      verify(storage.updateWidget()).called(1);
      if (!failTrips) expect(itemReads, 2);
    });
  }
}
