import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/mappers/trip/task_mapper.dart';
import 'package:memora/domain/entities/trip/task.dart' as entity;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'task_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('TaskMapper', () {
    test('FirestoreドキュメントからTaskDtoへ変換できる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('task001');
      when(mockDoc.data()).thenReturn({
        'tripId': 'trip001',
        'orderIndex': 0,
        'parentTaskId': 'task-parent',
        'name': '準備',
        'isCompleted': true,
        'dueDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'memo': 'メモ',
        'assignedMemberId': 'member001',
      });

      final dto = TaskMapper.fromFirestore(mockDoc);

      expect(dto.id, 'task001');
      expect(dto.tripId, 'trip001');
      expect(dto.orderIndex, 0);
      expect(dto.parentTaskId, 'task-parent');
      expect(dto.name, '準備');
      expect(dto.isCompleted, true);
      expect(dto.dueDate, DateTime(2024, 1, 1));
      expect(dto.memo, 'メモ');
      expect(dto.assignedMemberId, 'member001');
    });

    test('Firestoreの欠損値はデフォルトで補完される', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('task001');
      when(mockDoc.data()).thenReturn({});

      final dto = TaskMapper.fromFirestore(mockDoc);

      expect(dto.tripId, '');
      expect(dto.orderIndex, 0);
      expect(dto.name, '');
      expect(dto.isCompleted, false);
    });

    test('TaskDtoからTaskエンティティへ変換できる', () {
      final dto = TaskDto(
        id: 'task001',
        tripId: 'trip001',
        orderIndex: 0,
        parentTaskId: 'task-parent',
        name: '準備',
        isCompleted: false,
        dueDate: DateTime(2024, 1, 1),
        memo: 'メモ',
        assignedMemberId: 'member001',
      );

      final task = TaskMapper.toEntity(dto);

      expect(
        task,
        entity.Task(
          tripId: 'trip001',
          orderIndex: 0,
          parentTaskId: 'task-parent',
          name: '準備',
          isCompleted: false,
          dueDate: DateTime(2024, 1, 1),
          memo: 'メモ',
          assignedMemberId: 'member001',
        ),
      );
    });

    test('TaskDtoのリストをエンティティリストに変換できる', () {
      final dtos = [
        TaskDto(
          id: 'task001',
          tripId: 'trip001',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
        TaskDto(
          id: 'task002',
          tripId: 'trip001',
          orderIndex: 1,
          name: '確認',
          isCompleted: true,
        ),
      ];

      final entities = TaskMapper.toEntityList(dtos);

      expect(entities, hasLength(2));
      expect(entities.last.orderIndex, 1);
    });
  });
}
