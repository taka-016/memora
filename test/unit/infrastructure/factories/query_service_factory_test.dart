import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/queries/trip/firestore_itinerary_item_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_exception.dart';
import 'query_service_factory_test.mocks.dart';

@GenerateMocks([FirebaseFirestore])
void main() {
  group('QueryServiceFactory', () {
    test('ItineraryItemQueryServiceはFirestore実装を返す', () {
      final container = ProviderContainer(
        overrides: [
          firebaseFirestoreProvider.overrideWithValue(MockFirebaseFirestore()),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(itineraryItemQueryServiceProvider);

      expect(service, isA<ItineraryItemQueryService>());
      expect(service, isA<FirestoreItineraryItemQueryService>());
    });

    test('共有のTripEntryQueryServiceは取得失敗時に空リストを返す', () async {
      final firestore = MockFirebaseFirestore();
      when(firestore.collection(any)).thenThrow(TestException('取得失敗'));
      final container = ProviderContainer(
        overrides: [firebaseFirestoreProvider.overrideWithValue(firestore)],
      );
      addTearDown(container.dispose);

      final service = container.read(tripEntryQueryServiceProvider);

      expect(await service.getTripEntriesByGroupId('group1'), isEmpty);
    });

    test('地図用のTripEntryQueryServiceは取得失敗時に例外を再送出する', () async {
      final firestore = MockFirebaseFirestore();
      when(firestore.collection(any)).thenThrow(TestException('取得失敗'));
      final container = ProviderContainer(
        overrides: [firebaseFirestoreProvider.overrideWithValue(firestore)],
      );
      addTearDown(container.dispose);

      final TripEntryQueryService service = container.read(
        mapTripEntryQueryServiceProvider,
      );

      expect(
        () => service.getTripEntriesByGroupId('group1'),
        throwsA(isA<TestException>()),
      );
    });
  });
}
