import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_mapper.dart';
import 'package:memora/domain/entities/group/group.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('FirestoreGroupMapper', () {
    test('GroupからFirestoreのMapへ変換できる', () {
      final group = Group(
        id: 'group001',
        ownerId: 'admin001',
        name: 'テストグループ',
        memo: 'テストメモ',
      );

      final data = FirestoreGroupMapper.toFirestore(group);

      expect(data['ownerId'], 'admin001');
      expect(data['name'], 'テストグループ');
      expect(data['memo'], 'テストメモ');
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('nullableなフィールドがnullでもFirestoreのMapへ変換できる', () {
      final group = Group(
        id: 'group002',
        ownerId: 'admin002',
        name: 'テストグループ2',
      );

      final data = FirestoreGroupMapper.toFirestore(group);

      expect(data['ownerId'], 'admin002');
      expect(data['name'], 'テストグループ2');
      expect(data['memo'], null);
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('空文字を含むGroupからFirestoreのMapへ変換できる', () {
      final group = Group(id: 'group004', ownerId: '', name: '');

      final data = FirestoreGroupMapper.toFirestore(group);

      expect(data['ownerId'], '');
      expect(data['name'], '');
      expect(data['memo'], null);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
