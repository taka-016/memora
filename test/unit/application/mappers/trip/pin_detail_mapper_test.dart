import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_detail_dto.dart';
import 'package:memora/application/mappers/trip/pin_detail_mapper.dart';
import 'package:memora/domain/entities/trip/pin_detail.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'pin_detail_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('PinDetailMapper', () {
    test('FirestoreのドキュメントからPinDetailDtoへ変換できる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.data()).thenReturn({
        'pinId': 'pin-100',
        'name': '昼食',
        'startDate': Timestamp.fromDate(DateTime(2024, 4, 10, 12, 0)),
        'endDate': Timestamp.fromDate(DateTime(2024, 4, 10, 13, 0)),
        'memo': 'レストランで食事',
      });

      final dto = PinDetailMapper.fromFirestore(mockDoc);

      expect(dto.pinId, 'pin-100');
      expect(dto.name, '昼食');
      expect(dto.startDate, DateTime(2024, 4, 10, 12, 0));
      expect(dto.endDate, DateTime(2024, 4, 10, 13, 0));
      expect(dto.memo, 'レストランで食事');
    });

    test('Firestoreの値が存在しない場合はデフォルト値を使用する', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.data()).thenReturn(null);

      final dto = PinDetailMapper.fromFirestore(mockDoc);

      expect(dto.pinId, '');
      expect(dto.name, isNull);
      expect(dto.startDate, isNull);
      expect(dto.endDate, isNull);
      expect(dto.memo, isNull);
    });

    test('PinDetailDtoからPinDetailエンティティへ変換できる', () {
      final dto = PinDetailDto(
        pinId: 'pin-101',
        name: '夕食',
        startDate: DateTime(2024, 4, 10, 18, 0),
        endDate: DateTime(2024, 4, 10, 19, 0),
        memo: '海鮮料理',
      );

      final entity = PinDetailMapper.toEntity(dto);

      expect(
        entity,
        PinDetail(
          pinId: 'pin-101',
          name: '夕食',
          startDate: DateTime(2024, 4, 10, 18, 0),
          endDate: DateTime(2024, 4, 10, 19, 0),
          memo: '海鮮料理',
        ),
      );
    });

    test('PinDetailエンティティからPinDetailDtoへ変換できる', () {
      final entity = PinDetail(
        pinId: 'pin-102',
        name: 'チェックイン',
        startDate: DateTime(2024, 4, 10, 15, 0),
        endDate: DateTime(2024, 4, 10, 15, 30),
        memo: 'ホテル到着',
      );

      final dto = PinDetailMapper.toDto(entity);

      expect(dto.pinId, 'pin-102');
      expect(dto.name, 'チェックイン');
      expect(dto.startDate, DateTime(2024, 4, 10, 15, 0));
      expect(dto.endDate, DateTime(2024, 4, 10, 15, 30));
      expect(dto.memo, 'ホテル到着');
    });

    test('PinDetailDtoのリストをエンティティリストに変換できる', () {
      final dtos = [
        PinDetailDto(
          pinId: 'pin-201',
          startDate: DateTime(2024, 4, 11, 9, 0),
          endDate: DateTime(2024, 4, 11, 10, 0),
        ),
        PinDetailDto(
          pinId: 'pin-202',
          startDate: DateTime(2024, 4, 12, 9, 0),
          endDate: DateTime(2024, 4, 12, 10, 0),
        ),
      ];

      final entities = PinDetailMapper.toEntityList(dtos);

      expect(entities.length, 2);
      expect(entities[0].pinId, 'pin-201');
      expect(entities[1].pinId, 'pin-202');
    });

    test('PinDetailエンティティのリストをDtoリストに変換できる', () {
      final entities = [
        PinDetail(
          pinId: 'pin-301',
          startDate: DateTime(2024, 4, 13, 11, 0),
          endDate: DateTime(2024, 4, 13, 12, 0),
        ),
        PinDetail(
          pinId: 'pin-302',
          startDate: DateTime(2024, 4, 14, 11, 0),
          endDate: DateTime(2024, 4, 14, 12, 0),
        ),
      ];

      final dtos = PinDetailMapper.toDtoList(entities);

      expect(dtos.length, 2);
      expect(dtos[0].pinId, 'pin-301');
      expect(dtos[1].pinId, 'pin-302');
    });
  });
}
