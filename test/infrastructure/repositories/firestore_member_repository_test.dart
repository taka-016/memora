import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_member_repository.dart';
import 'package:memora/domain/entities/member.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentSnapshot,
])
import 'firestore_member_repository_test.mocks.dart';

void main() {
  group('FirestoreMemberRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreMemberRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc2;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
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
        nickname: 'たろちゃん',
        type: '一般',
        birthday: DateTime(2000, 1, 1),
        gender: 'male',
        email: 'taro@example.com',
      );

      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

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
              containsPair('nickname', 'たろちゃん'),
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

    test('getMembersがFirestoreからMemberのリストを返す', () async {
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockDoc1.id).thenReturn('member001');
      when(mockDoc1.data()).thenReturn({
        'hiraganaFirstName': 'たろう',
        'hiraganaLastName': 'やまだ',
        'kanjiFirstName': '太郎',
        'kanjiLastName': '山田',
        'firstName': 'Taro',
        'lastName': 'Yamada',
        'nickname': 'たろちゃん',
        'type': '一般',
        'birthday': Timestamp.fromDate(DateTime(2000, 1, 1)),
        'gender': 'male',
        'email': 'taro@example.com',
      });
      when(mockDoc2.id).thenReturn('member002');
      when(mockDoc2.data()).thenReturn({
        'hiraganaFirstName': 'はなこ',
        'hiraganaLastName': 'やまだ',
        'kanjiFirstName': '花子',
        'kanjiLastName': '山田',
        'firstName': 'Hanako',
        'lastName': 'Yamada',
        'type': '一般',
        'birthday': Timestamp.fromDate(DateTime(2001, 2, 2)),
        'gender': 'female',
      });

      final result = await repository.getMembers();

      expect(result.length, 2);
      expect(result[0].id, 'member001');
      expect(result[0].hiraganaFirstName, 'たろう');
      expect(result[0].nickname, 'たろちゃん');
      expect(result[0].email, 'taro@example.com');
      expect(result[1].id, 'member002');
      expect(result[1].hiraganaFirstName, 'はなこ');
      expect(result[1].nickname, null);
      expect(result[1].email, null);
    });

    test('getMembersがエラー時に空のリストを返す', () async {
      when(mockCollection.get()).thenThrow(Exception('Firestore error'));

      final result = await repository.getMembers();

      expect(result, isEmpty);
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

    test('getMemberByIdが特定のメンバーを返す', () async {
      const memberId = 'member001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockCollection.doc(memberId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.id).thenReturn(memberId);
      when(mockDocSnapshot.data()).thenReturn({
        'hiraganaFirstName': 'たろう',
        'hiraganaLastName': 'やまだ',
        'kanjiFirstName': '太郎',
        'kanjiLastName': '山田',
        'firstName': 'Taro',
        'lastName': 'Yamada',
        'type': '一般',
        'birthday': Timestamp.fromDate(DateTime(2000, 1, 1)),
        'gender': 'male',
      });

      final result = await repository.getMemberById(memberId);

      expect(result, isNotNull);
      expect(result!.id, memberId);
      expect(result.hiraganaFirstName, 'たろう');
    });

    test('getMemberByIdが存在しないメンバーでnullを返す', () async {
      const memberId = 'nonexistent';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockCollection.doc(memberId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(false);

      final result = await repository.getMemberById(memberId);

      expect(result, isNull);
    });
  });
}
