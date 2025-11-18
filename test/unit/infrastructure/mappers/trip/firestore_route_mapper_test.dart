import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/domain/entities/trip/route.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_route_mapper.dart'
    as firestore_mapper;

void main() {
  group('FirestoreRouteMapper', () {
    test('RouteエンティティをFirestoreマップへ変換できる', () {
      final route = Route(
        id: 'route001',
        tripId: 'trip001',
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.walk,
        distanceMeters: 1000,
        durationSeconds: 300,
        instructions: '直進',
        polyline: 'abc',
      );

      final map = firestore_mapper.FirestoreRouteMapper.toFirestore(route);

      expect(map['tripId'], 'trip001');
      expect(map['orderIndex'], 0);
      expect(map['departurePinId'], 'pinA');
      expect(map['arrivalPinId'], 'pinB');
      expect(map['travelMode'], 'WALK');
      expect(map['distanceMeters'], 1000);
      expect(map['durationSeconds'], 300);
      expect(map['instructions'], '直進');
      expect(map['polyline'], 'abc');
      expect(map['createdAt'], isNotNull);
    });
  });
}
