import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_task_mapper.dart';

import '../../../../helpers/fake_document_snapshot.dart';

void main() {
  group('FirestoreTaskMapper', () {
    test('FirestoreドキュメントからTaskDtoへ変換できる', () {
      final doc = FakeDocumentSnapshot(
        docId: 'task001',
        data: {
          'tripId': 'trip001',
          'orderIndex': 1,
          'name': '準備',
          'isCompleted': false,
        },
      );

      final dto = FirestoreTaskMapper.fromFirestore(doc);

      expect(dto.id, 'task001');
      expect(dto.tripId, 'trip001');
      expect(dto.orderIndex, 1);
      expect(dto.name, '準備');
      expect(dto.isCompleted, isFalse);
    });

    test('Firestoreの欠損値はデフォルトで補完する', () {
      final doc = FakeDocumentSnapshot(docId: 'task002', data: {});

      final dto = FirestoreTaskMapper.fromFirestore(doc);

      expect(dto.id, 'task002');
      expect(dto.tripId, '');
      expect(dto.orderIndex, 0);
      expect(dto.name, '');
      expect(dto.isCompleted, isFalse);
    });

    test('TaskエンティティをFirestoreマップへ変換できる', () {
      final task = Task(
        id: 'task003',
        tripId: 'trip003',
        orderIndex: 0,
        name: '準備',
        isCompleted: true,
      );

      final map = FirestoreTaskMapper.toFirestore(task);

      expect(map['tripId'], 'trip003');
      expect(map['orderIndex'], 0);
      expect(map['name'], '準備');
      expect(map['isCompleted'], isTrue);
      expect(map['createdAt'], isNotNull);
    });
  });
}
