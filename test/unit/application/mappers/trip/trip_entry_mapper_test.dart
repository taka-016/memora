import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';
import 'package:memora/domain/entities/trip/pin.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'trip_entry_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('TripEntryMapper', () {
    test('FirestoreのドキュメントからTripEntryDtoへ変換できる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('trip-001');
      when(mockDoc.data()).thenReturn({
        'groupId': 'group-001',
        'tripName': '春の旅行',
        'tripStartDate': Timestamp.fromDate(DateTime(2024, 3, 20)),
        'tripEndDate': Timestamp.fromDate(DateTime(2024, 3, 25)),
        'tripMemo': '家族旅行',
      });

      final pinDtos = [
        PinDto(
          pinId: 'pin-001',
          tripId: 'trip-001',
          groupId: 'group-001',
          latitude: 35.0,
          longitude: 135.0,
        ),
      ];

      final dto = TripEntryMapper.fromFirestore(mockDoc, pins: pinDtos);

      expect(dto.id, 'trip-001');
      expect(dto.groupId, 'group-001');
      expect(dto.tripName, '春の旅行');
      expect(dto.tripStartDate, DateTime(2024, 3, 20));
      expect(dto.tripEndDate, DateTime(2024, 3, 25));
      expect(dto.tripMemo, '家族旅行');
      expect(dto.pins, pinDtos);
    });

    test('Firestoreの必須フィールドが欠けていてもデフォルト値で変換できる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('trip-002');
      when(mockDoc.data()).thenReturn({'groupId': 'group-002'});

      final dto = TripEntryMapper.fromFirestore(mockDoc);

      expect(dto.id, 'trip-002');
      expect(dto.groupId, 'group-002');
      expect(dto.tripName, isNull);
      expect(dto.tripMemo, isNull);
      expect(dto.tripStartDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(dto.tripEndDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(dto.pins, isEmpty);
    });

    test('TripEntryDtoからTripEntryエンティティへ変換できる', () {
      final dto = TripEntryDto(
        id: 'trip-003',
        groupId: 'group-003',
        tripName: '夏の旅行',
        tripStartDate: DateTime(2024, 7, 1),
        tripEndDate: DateTime(2024, 7, 5),
        tripMemo: '海水浴に行く',
        pins: [
          PinDto(
            pinId: 'pin-010',
            tripId: 'trip-003',
            groupId: 'group-003',
            latitude: 34.0,
            longitude: 134.0,
            locationName: '海岸',
          ),
        ],
      );

      final entity = TripEntryMapper.toEntity(dto);

      expect(
        entity,
        TripEntry(
          id: 'trip-003',
          groupId: 'group-003',
          tripName: '夏の旅行',
          tripStartDate: DateTime(2024, 7, 1),
          tripEndDate: DateTime(2024, 7, 5),
          tripMemo: '海水浴に行く',
          pins: [
            Pin(
              pinId: 'pin-010',
              tripId: 'trip-003',
              groupId: 'group-003',
              latitude: 34.0,
              longitude: 134.0,
              locationName: '海岸',
            ),
          ],
        ),
      );
    });

    test('TripEntryDtoのリストをエンティティリストに変換できる', () {
      final dtos = [
        TripEntryDto(
          id: 'trip-101',
          groupId: 'group-101',
          tripStartDate: DateTime(2024, 4, 1),
          tripEndDate: DateTime(2024, 4, 3),
        ),
        TripEntryDto(
          id: 'trip-102',
          groupId: 'group-102',
          tripStartDate: DateTime(2024, 5, 1),
          tripEndDate: DateTime(2024, 5, 5),
        ),
      ];

      final entities = TripEntryMapper.toEntityList(dtos);

      expect(entities.length, 2);
      expect(entities[0].id, 'trip-101');
      expect(entities[0].groupId, 'group-101');
      expect(entities[1].id, 'trip-102');
      expect(entities[1].groupId, 'group-102');
    });
  });
}
