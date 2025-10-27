import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/mappers/member/member_event_mapper.dart';
import 'package:memora/domain/entities/member/member_event.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'member_event_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('MemberEventMapper', () {
    test('FirestoreのドキュメントからMemberEventDtoへ変換できる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('member-event-001');
      when(mockDoc.data()).thenReturn({
        'memberId': 'member-001',
        'type': 'training',
        'name': 'トレーニング',
        'startDate': Timestamp.fromDate(DateTime(2024, 4, 1, 9)),
        'endDate': Timestamp.fromDate(DateTime(2024, 4, 1, 11)),
        'memo': '体育館で実施',
      });

      final dto = MemberEventMapper.fromFirestore(mockDoc);

      expect(dto.id, 'member-event-001');
      expect(dto.memberId, 'member-001');
      expect(dto.type, 'training');
      expect(dto.name, 'トレーニング');
      expect(dto.startDate, DateTime(2024, 4, 1, 9));
      expect(dto.endDate, DateTime(2024, 4, 1, 11));
      expect(dto.memo, '体育館で実施');
    });

    test('Firestoreの値が不足している場合はデフォルト値で補完する', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('member-event-002');
      when(mockDoc.data()).thenReturn({'memberId': 'member-002'});

      final dto = MemberEventMapper.fromFirestore(mockDoc);

      expect(dto.id, 'member-event-002');
      expect(dto.memberId, 'member-002');
      expect(dto.type, '');
      expect(dto.name, isNull);
      expect(dto.startDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(dto.endDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(dto.memo, isNull);
    });

    test('MemberEventDtoからエンティティへ変換できる', () {
      final dto = MemberEventDto(
        id: 'member-event-003',
        memberId: 'member-010',
        type: 'meeting',
        name: '面談',
        startDate: DateTime(2024, 4, 2, 14),
        endDate: DateTime(2024, 4, 2, 15),
        memo: '評価面談',
      );

      final entity = MemberEventMapper.toEntity(dto);

      expect(
        entity,
        MemberEvent(
          id: 'member-event-003',
          memberId: 'member-010',
          type: 'meeting',
          name: '面談',
          startDate: DateTime(2024, 4, 2, 14),
          endDate: DateTime(2024, 4, 2, 15),
          memo: '評価面談',
        ),
      );
    });

    test('MemberEventエンティティからDtoへ変換できる', () {
      final entity = MemberEvent(
        id: 'member-event-004',
        memberId: 'member-020',
        type: 'outing',
        name: '外出',
        startDate: DateTime(2024, 4, 3, 10),
        endDate: DateTime(2024, 4, 3, 12),
        memo: '買い物',
      );

      final dto = MemberEventMapper.toDto(entity);

      expect(dto.id, 'member-event-004');
      expect(dto.memberId, 'member-020');
      expect(dto.type, 'outing');
      expect(dto.name, '外出');
      expect(dto.startDate, DateTime(2024, 4, 3, 10));
      expect(dto.endDate, DateTime(2024, 4, 3, 12));
      expect(dto.memo, '買い物');
    });

    test('Dtoリストからエンティティリストへ変換できる', () {
      final dtos = [
        MemberEventDto(
          id: 'member-event-101',
          memberId: 'member-101',
          type: 'training',
          startDate: DateTime(2024, 4, 4, 9),
          endDate: DateTime(2024, 4, 4, 11),
        ),
        MemberEventDto(
          id: 'member-event-102',
          memberId: 'member-102',
          type: 'meeting',
          startDate: DateTime(2024, 4, 5, 9),
          endDate: DateTime(2024, 4, 5, 11),
        ),
      ];

      final entities = MemberEventMapper.toEntityList(dtos);

      expect(entities.length, 2);
      expect(entities[0].id, 'member-event-101');
      expect(entities[1].type, 'meeting');
    });

    test('エンティティリストからDtoリストへ変換できる', () {
      final entities = [
        MemberEvent(
          id: 'member-event-201',
          memberId: 'member-201',
          type: 'training',
          startDate: DateTime(2024, 4, 6, 9),
          endDate: DateTime(2024, 4, 6, 11),
        ),
        MemberEvent(
          id: 'member-event-202',
          memberId: 'member-202',
          type: 'outing',
          startDate: DateTime(2024, 4, 7, 9),
          endDate: DateTime(2024, 4, 7, 11),
        ),
      ];

      final dtos = MemberEventMapper.toDtoList(entities);

      expect(dtos.length, 2);
      expect(dtos[0].id, 'member-event-201');
      expect(dtos[1].type, 'outing');
    });
  });
}
