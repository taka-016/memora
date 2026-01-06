import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_task_mapper.dart'
    as firestore_mapper;

void main() {
  group('FirestoreTaskMapper', () {
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

      final map = firestore_mapper.FirestoreTaskMapper.toFirestore(task);

      expect(map['tripId'], 'trip001');
      expect(map['orderIndex'], 0);
      expect(map['parentTaskId'], 'task-parent');
      expect(map['name'], '準備');
      expect(map['isCompleted'], true);
      expect(map['memo'], 'メモ');
      expect(map['assignedMemberId'], 'member001');
      expect(map['dueDate'], isNotNull);
      expect(map['createdAt'], isNotNull);
    });
  });
}
