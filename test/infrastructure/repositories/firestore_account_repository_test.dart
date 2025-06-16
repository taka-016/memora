import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_account_repository.dart';
import 'package:memora/domain/entities/account.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentSnapshot,
  Query,
])
import 'firestore_account_repository_test.mocks.dart';

void main() {
  group('FirestoreAccountRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreAccountRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;
    late MockQuery<Map<String, dynamic>> mockQuery;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      when(mockFirestore.collection('accounts')).thenReturn(mockCollection);
      repository = FirestoreAccountRepository(firestore: mockFirestore);
    });

    test('saveAccountがaccounts collectionにアカウント情報をaddする', () async {
      final account = Account(
        id: 'account001',
        email: 'test@example.com',
        password: 'password123',
        name: 'テストユーザー',
        memberId: 'member001',
      );

      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.saveAccount(account);

      verify(
        mockCollection.add(
          argThat(
            allOf([
              containsPair('email', 'test@example.com'),
              containsPair('password', 'password123'),
              containsPair('name', 'テストユーザー'),
              containsPair('memberId', 'member001'),
              contains('createdAt'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('getAccountsがFirestoreからAccountのリストを返す', () async {
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('account001');
      when(mockDoc1.data()).thenReturn({
        'email': 'test@example.com',
        'password': 'password123',
        'name': 'テストユーザー',
        'memberId': 'member001',
      });

      final result = await repository.getAccounts();

      expect(result.length, 1);
      expect(result[0].id, 'account001');
      expect(result[0].email, 'test@example.com');
      expect(result[0].name, 'テストユーザー');
      expect(result[0].memberId, 'member001');
    });

    test('getAccountsがエラー時に空のリストを返す', () async {
      when(mockCollection.get()).thenThrow(Exception('Firestore error'));

      final result = await repository.getAccounts();

      expect(result, isEmpty);
    });

    test('deleteAccountがaccounts collectionの該当ドキュメントを削除する', () async {
      const accountId = 'account001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc(accountId)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deleteAccount(accountId);

      verify(mockCollection.doc(accountId)).called(1);
      verify(mockDocRef.delete()).called(1);
    });

    test('getAccountByIdが特定のアカウントを返す', () async {
      const accountId = 'account001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockCollection.doc(accountId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.id).thenReturn(accountId);
      when(mockDocSnapshot.data()).thenReturn({
        'email': 'test@example.com',
        'password': 'password123',
        'name': 'テストユーザー',
        'memberId': 'member001',
      });

      final result = await repository.getAccountById(accountId);

      expect(result, isNotNull);
      expect(result!.id, accountId);
      expect(result.email, 'test@example.com');
    });

    test('getAccountByIdが存在しないアカウントでnullを返す', () async {
      const accountId = 'nonexistent';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockCollection.doc(accountId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(false);

      final result = await repository.getAccountById(accountId);

      expect(result, isNull);
    });

    test('getAccountByEmailがメールアドレスでアカウントを返す', () async {
      const email = 'test@example.com';

      when(mockCollection.where('email', isEqualTo: email)).thenReturn(mockQuery);
      when(mockQuery.limit(1)).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('account001');
      when(mockDoc1.data()).thenReturn({
        'email': email,
        'password': 'password123',
        'name': 'テストユーザー',
        'memberId': 'member001',
      });

      final result = await repository.getAccountByEmail(email);

      expect(result, isNotNull);
      expect(result!.id, 'account001');
      expect(result.email, email);
    });

    test('getAccountByEmailが存在しないメールアドレスでnullを返す', () async {
      const email = 'nonexistent@example.com';

      when(mockCollection.where('email', isEqualTo: email)).thenReturn(mockQuery);
      when(mockQuery.limit(1)).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([]);

      final result = await repository.getAccountByEmail(email);

      expect(result, isNull);
    });
  });
}