import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/route_dto.dart';
import 'package:memora/application/mappers/trip/route_mapper.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/domain/entities/trip/route.dart' as entity;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'route_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('RouteMapper', () {
    test('FirestoreドキュメントからRouteDtoへ変換できる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('route001');
      when(mockDoc.data()).thenReturn({
        'tripId': 'trip001',
        'orderIndex': 1,
        'departurePinId': 'pinA',
        'arrivalPinId': 'pinB',
        'travelMode': 'WALK',
        'distanceMeters': 1500,
        'durationSeconds': 600,
        'instructions': '直進',
        'polyline': 'encoded',
      });

      final dto = RouteMapper.fromFirestore(mockDoc);

      expect(dto.id, 'route001');
      expect(dto.tripId, 'trip001');
      expect(dto.orderIndex, 1);
      expect(dto.travelMode, TravelMode.walk);
      expect(dto.distanceMeters, 1500);
      expect(dto.instructions, '直進');
      expect(dto.polyline, 'encoded');
    });

    test('Firestoreの欠損値はデフォルトで補完される', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('route001');
      when(mockDoc.data()).thenReturn({});

      final dto = RouteMapper.fromFirestore(mockDoc);

      expect(dto.tripId, '');
      expect(dto.orderIndex, 0);
      expect(dto.departurePinId, '');
      expect(dto.arrivalPinId, '');
      expect(dto.travelMode, TravelMode.other);
    });

    test('RouteDtoからRouteエンティティへ変換できる', () {
      final dto = RouteDto(
        id: 'route001',
        tripId: 'trip001',
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.drive,
        distanceMeters: 1000,
        durationSeconds: 300,
        instructions: '直進',
        polyline: 'encoded',
      );

      final entityRoute = RouteMapper.toEntity(dto);

      expect(
        entityRoute,
        entity.Route(
          id: 'route001',
          tripId: 'trip001',
          orderIndex: 0,
          departurePinId: 'pinA',
          arrivalPinId: 'pinB',
          travelMode: TravelMode.drive,
          distanceMeters: 1000,
          durationSeconds: 300,
          instructions: '直進',
          polyline: 'encoded',
        ),
      );
    });

    test('RouteDtoのリストをエンティティリストに変換できる', () {
      final dtos = [
        RouteDto(
          id: 'route001',
          tripId: 'trip001',
          orderIndex: 0,
          departurePinId: 'pinA',
          arrivalPinId: 'pinB',
          travelMode: TravelMode.drive,
        ),
        RouteDto(
          id: 'route002',
          tripId: 'trip001',
          orderIndex: 1,
          departurePinId: 'pinB',
          arrivalPinId: 'pinC',
          travelMode: TravelMode.walk,
        ),
      ];

      final entities = RouteMapper.toEntityList(dtos);

      expect(entities, hasLength(2));
      expect(entities.first.id, 'route001');
      expect(entities.last.orderIndex, 1);
    });
  });
}
