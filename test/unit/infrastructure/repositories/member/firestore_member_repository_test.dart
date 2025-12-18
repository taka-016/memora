import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_repository.dart';
import 'package:memora/domain/entities/member/member.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentSnapshot,
  Query,
])
import 'firestore_member_repository_test.mocks.dart';

void main() {
  group('FirestoreMemberRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreMemberRepository repository;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      when(mockFirestore.collection('members')).thenReturn(mockCollection);
      repository = FirestoreMemberRepository(firestore: mockFirestore);
    });

    test('saveMemberがmembers collectionにメンバー情報をaddする', () async {
      final member = Member(
        id: 'member001',
        hiraganaFirstName: 'たろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
        firstName: 'Taro',
        lastName: 'Yamada',
        displayName: 'たろちゃん',
        type: '一般',
        birthday: DateTime(2000, 1, 1),
        gender: 'male',
        email: 'taro@example.com',
      );

      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      when(mockCollection.add(any)).thenAnswer((_) async => mockDocRef);

      await repository.saveMember(member);

      verify(
        mockCollection.add(
          argThat(
            allOf([
              containsPair('hiraganaFirstName', 'たろう'),
              containsPair('hiraganaLastName', 'やまだ'),
              containsPair('kanjiFirstName', '太郎'),
              containsPair('kanjiLastName', '山田'),
              containsPair('firstName', 'Taro'),
              containsPair('lastName', 'Yamada'),
              containsPair('displayName', 'たろちゃん'),
              containsPair('type', '一般'),
              containsPair('gender', 'male'),
              containsPair('email', 'taro@example.com'),
              contains('birthday'),
              contains('createdAt'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('deleteMemberがmembers collectionの該当ドキュメントを削除する', () async {
      const memberId = 'member001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc(memberId)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deleteMember(memberId);

      verify(mockCollection.doc(memberId)).called(1);
      verify(mockDocRef.delete()).called(1);
    });

    test(
      'nullifyAccountIdがmembers collectionの該当ドキュメントのaccountIdをnullにする',
      () async {
        const memberId = 'member001';
        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

        when(mockCollection.doc(memberId)).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenAnswer((_) async {});

        await repository.nullifyAccountId(memberId);

        verify(mockCollection.doc(memberId)).called(1);
        verify(
          mockDocRef.update(argThat(containsPair('accountId', null))),
        ).called(1);
      },
    );
  });
}
