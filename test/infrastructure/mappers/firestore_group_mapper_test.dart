import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/firestore_group_mapper.dart';
import 'package:memora/domain/entities/group.dart';
import '../repositories/firestore_group_repository_test.mocks.dart';

void main() {
  group('FirestoreGroupMapper', () {
    test('FirestoreのDocumentSnapshotからGroupへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('group001');
      when(mockDoc.data()).thenReturn({
        'name': 'テストグループ',
        'memo': 'テストメモ',
      });

      final group = FirestoreGroupMapper.fromFirestore(mockDoc);

      expect(group.id, 'group001');
      expect(group.name, 'テストグループ');
      expect(group.memo, 'テストメモ');
    });

    test('nullableなフィールドがnullの場合でも変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('group002');
      when(mockDoc.data()).thenReturn({
        'name': 'テストグループ2',
      });

      final group = FirestoreGroupMapper.fromFirestore(mockDoc);

      expect(group.id, 'group002');
      expect(group.name, 'テストグループ2');
      expect(group.memo, null);
    });

    test('GroupからFirestoreのMapへ変換できる', () {
      final group = Group(
        id: 'group001',
        name: 'テストグループ',
        memo: 'テストメモ',
      );

      final data = FirestoreGroupMapper.toFirestore(group);

      expect(data['name'], 'テストグループ');
      expect(data['memo'], 'テストメモ');
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('nullableなフィールドがnullでもFirestoreのMapへ変換できる', () {
      final group = Group(
        id: 'group002',
        name: 'テストグループ2',
      );

      final data = FirestoreGroupMapper.toFirestore(group);

      expect(data['name'], 'テストグループ2');
      expect(data['memo'], null);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}