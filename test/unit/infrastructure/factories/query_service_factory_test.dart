import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/queries/trip/firestore_itinerary_item_query_service.dart';
import 'package:mockito/annotations.dart';

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
  });
}
