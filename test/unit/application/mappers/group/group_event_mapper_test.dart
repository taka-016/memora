import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/mappers/group/group_event_mapper.dart';
import 'package:memora/domain/entities/group/group_event.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'group_event_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('GroupEventMapper', () {
    test('FirestoreのドキュメントからGroupEventDtoへ変換できる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('event-001');
      when(mockDoc.data()).thenReturn({
        'groupId': 'group-001',
        'type': 'trip',
        'name': '春合宿',
        'startDate': Timestamp.fromDate(DateTime(2024, 3, 1)),
        'endDate': Timestamp.fromDate(DateTime(2024, 3, 3)),
        'memo': '山梨で開催',
      });

      final dto = GroupEventMapper.fromFirestore(mockDoc);

      expect(dto.id, 'event-001');
      expect(dto.groupId, 'group-001');
      expect(dto.type, 'trip');
      expect(dto.name, '春合宿');
      expect(dto.startDate, DateTime(2024, 3, 1));
      expect(dto.endDate, DateTime(2024, 3, 3));
      expect(dto.memo, '山梨で開催');
    });

    test('Firestoreの値が不足している場合はデフォルト値で補完する', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('event-002');
      when(mockDoc.data()).thenReturn({'groupId': 'group-002'});

      final dto = GroupEventMapper.fromFirestore(mockDoc);

      expect(dto.id, 'event-002');
      expect(dto.groupId, 'group-002');
      expect(dto.type, '');
      expect(dto.name, isNull);
      expect(dto.startDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(dto.endDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(dto.memo, isNull);
    });

    test('GroupEventDtoからエンティティへ変換できる', () {
      final dto = GroupEventDto(
        id: 'event-003',
        groupId: 'group-003',
        type: 'meeting',
        name: '定例会議',
        startDate: DateTime(2024, 4, 5, 10),
        endDate: DateTime(2024, 4, 5, 12),
        memo: '資料共有あり',
      );

      final entity = GroupEventMapper.toEntity(dto);

      expect(
        entity,
        GroupEvent(
          id: 'event-003',
          groupId: 'group-003',
          type: 'meeting',
          name: '定例会議',
          startDate: DateTime(2024, 4, 5, 10),
          endDate: DateTime(2024, 4, 5, 12),
          memo: '資料共有あり',
        ),
      );
    });

    test('GroupEventエンティティからDtoへ変換できる', () {
      final entity = GroupEvent(
        id: 'event-004',
        groupId: 'group-004',
        type: 'party',
        name: '打ち上げ',
        startDate: DateTime(2024, 5, 10, 19),
        endDate: DateTime(2024, 5, 10, 22),
        memo: '自由参加',
      );

      final dto = GroupEventMapper.toDto(entity);

      expect(dto.id, 'event-004');
      expect(dto.groupId, 'group-004');
      expect(dto.type, 'party');
      expect(dto.name, '打ち上げ');
      expect(dto.startDate, DateTime(2024, 5, 10, 19));
      expect(dto.endDate, DateTime(2024, 5, 10, 22));
      expect(dto.memo, '自由参加');
    });

    test('Dtoリストからエンティティリストへ変換できる', () {
      final dtos = [
        GroupEventDto(
          id: 'event-101',
          groupId: 'group-101',
          type: 'meeting',
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 1, 2),
        ),
        GroupEventDto(
          id: 'event-102',
          groupId: 'group-102',
          type: 'trip',
          startDate: DateTime(2024, 7, 10),
          endDate: DateTime(2024, 7, 12),
        ),
      ];

      final entities = GroupEventMapper.toEntityList(dtos);

      expect(entities.length, 2);
      expect(entities[0].id, 'event-101');
      expect(entities[1].type, 'trip');
    });

    test('エンティティリストからDtoリストへ変換できる', () {
      final entities = [
        GroupEvent(
          id: 'event-201',
          groupId: 'group-201',
          type: 'meeting',
          startDate: DateTime(2024, 8, 1),
          endDate: DateTime(2024, 8, 1, 1),
        ),
        GroupEvent(
          id: 'event-202',
          groupId: 'group-202',
          type: 'trip',
          startDate: DateTime(2024, 9, 1),
          endDate: DateTime(2024, 9, 3),
        ),
      ];

      final dtos = GroupEventMapper.toDtoList(entities);

      expect(dtos.length, 2);
      expect(dtos[0].id, 'event-201');
      expect(dtos[1].type, 'trip');
    });
  });
}
