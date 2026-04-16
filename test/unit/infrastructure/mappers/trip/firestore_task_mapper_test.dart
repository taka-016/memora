import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_task_mapper.dart'
    as firestore_mapper;

import 'firestore_task_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreTaskMapper', () {
    test('FirestoreドキュメントからTaskDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('task001');
      when(doc.data()).thenReturn({
        'tripId': 'trip001',
        'orderIndex': 1.9,
        'parentTaskId': 'parent001',
        'name': '荷造り',
        'isCompleted': true,
        'dueDate': Timestamp.fromDate(DateTime(2025, 2, 1)),
        'memo': '前日まで',
        'assignedMemberId': 'member001',
      });

      final result = firestore_mapper.FirestoreTaskMapper.fromFirestore(doc);

      expect(result.id, 'task001');
      expect(result.tripId, 'trip001');
      expect(result.orderIndex, 1);
      expect(result.parentTaskId, 'parent001');
      expect(result.name, '荷造り');
      expect(result.isCompleted, true);
      expect(result.dueDate, DateTime(2025, 2, 1));
      expect(result.memo, '前日まで');
      expect(result.assignedMemberId, 'member001');
    });

    test('Firestoreの欠損値をデフォルトで変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('task002');
      when(doc.data()).thenReturn({});

      final result = firestore_mapper.FirestoreTaskMapper.fromFirestore(doc);

      expect(result.id, 'task002');
      expect(result.tripId, '');
      expect(result.orderIndex, 0);
      expect(result.parentTaskId, isNull);
      expect(result.name, '');
      expect(result.isCompleted, false);
      expect(result.dueDate, isNull);
      expect(result.memo, isNull);
      expect(result.assignedMemberId, isNull);
    });

    test('TaskエンティティをFirestoreマップへ変換できる', () {
      final task = Task(
        id: 'task001',
        tripId: 'trip001',
        orderIndex: 0,
        parentTaskId: 'task-parent',
        name: '準備',
        isCompleted: true,
        dueDate: DateTime(2024, 1, 1),
        memo: 'メモ',
        assignedMemberId: 'member001',
      );

      final map = firestore_mapper.FirestoreTaskMapper.toCreateFirestore(task);

      expect(map['tripId'], 'trip001');
      expect(map['orderIndex'], 0);
      expect(map['parentTaskId'], 'task-parent');
      expect(map['name'], '準備');
      expect(map['isCompleted'], true);
      expect(map['memo'], 'メモ');
      expect(map['assignedMemberId'], 'member001');
      expect(map['dueDate'], isNotNull);
      expect(map['createdAt'], isNotNull);
      expect(map['updatedAt'], isNotNull);
    });

    test('Taskエンティティを更新用Firestoreマップへ変換できる', () {
      final task = Task(
        id: 'task001',
        tripId: 'trip001',
        orderIndex: 1,
        name: '更新準備',
        isCompleted: false,
      );

      final map = firestore_mapper.FirestoreTaskMapper.toUpdateFirestore(task);

      expect(map['tripId'], 'trip001');
      expect(map['orderIndex'], 1);
      expect(map['name'], '更新準備');
      expect(map['isCompleted'], false);
      expect(map.containsKey('createdAt'), isFalse);
      expect(map['updatedAt'], isNotNull);
    });
  });
}
