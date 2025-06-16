import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/firestore_account_mapper.dart';
import 'package:memora/domain/entities/account.dart';
import '../repositories/firestore_account_repository_test.mocks.dart';

void main() {
  group('FirestoreAccountMapper', () {
    test('FirestoreのDocumentSnapshotからAccountへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('account001');
      when(mockDoc.data()).thenReturn({
        'email': 'test@example.com',
        'password': 'password123',
        'name': 'テストユーザー',
        'memberId': 'member001',
      });

      final account = FirestoreAccountMapper.fromFirestore(mockDoc);

      expect(account.id, 'account001');
      expect(account.email, 'test@example.com');
      expect(account.password, 'password123');
      expect(account.name, 'テストユーザー');
      expect(account.memberId, 'member001');
    });

    test('nullableなフィールドがnullの場合でも変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('account002');
      when(mockDoc.data()).thenReturn({
        'email': 'test2@example.com',
        'password': 'password456',
        'name': 'テストユーザー2',
      });

      final account = FirestoreAccountMapper.fromFirestore(mockDoc);

      expect(account.id, 'account002');
      expect(account.email, 'test2@example.com');
      expect(account.password, 'password456');
      expect(account.name, 'テストユーザー2');
      expect(account.memberId, null);
    });

    test('AccountからFirestoreのMapへ変換できる', () {
      final account = Account(
        id: 'account001',
        email: 'test@example.com',
        password: 'password123',
        name: 'テストユーザー',
        memberId: 'member001',
      );

      final data = FirestoreAccountMapper.toFirestore(account);

      expect(data['email'], 'test@example.com');
      expect(data['password'], 'password123');
      expect(data['name'], 'テストユーザー');
      expect(data['memberId'], 'member001');
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('nullableなフィールドがnullでもFirestoreのMapへ変換できる', () {
      final account = Account(
        id: 'account002',
        email: 'test2@example.com',
        password: 'password456',
        name: 'テストユーザー2',
      );

      final data = FirestoreAccountMapper.toFirestore(account);

      expect(data['email'], 'test2@example.com');
      expect(data['password'], 'password456');
      expect(data['name'], 'テストユーザー2');
      expect(data['memberId'], null);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}