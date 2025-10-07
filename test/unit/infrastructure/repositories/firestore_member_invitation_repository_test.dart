import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_member_invitation_repository.dart';
import 'package:memora/domain/entities/member_invitation.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  Query,
])
import 'firestore_member_invitation_repository_test.mocks.dart';

void main() {
  group('FirestoreMemberInvitationRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreMemberInvitationRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;
    late MockQuery<Map<String, dynamic>> mockQuery;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      when(
        mockFirestore.collection('member_invitations'),
      ).thenReturn(mockCollection);
      repository = FirestoreMemberInvitationRepository(
        firestore: mockFirestore,
      );
    });

    test(
      'saveMemberInvitationがmember_invitations collectionにメンバー招待情報をaddする（新規作成）',
      () async {
        final memberInvitation = MemberInvitation(
          id: '',
          inviterId: 'inviter001',
          inviteeId: 'invitee001',
          invitationCode: 'CODE123',
        );

        when(mockCollection.add(any)).thenAnswer(
          (_) async => MockDocumentReference<Map<String, dynamic>>(),
        );

        await repository.saveMemberInvitation(memberInvitation);

        verify(
          mockCollection.add(
            argThat(
              allOf([
                containsPair('inviterId', 'inviter001'),
                containsPair('inviteeId', 'invitee001'),
                containsPair('invitationCode', 'CODE123'),
              ]),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'saveMemberInvitationがmember_invitations collectionのドキュメントを更新する（更新）',
      () async {
        final memberInvitation = MemberInvitation(
          id: 'invitation001',
          inviterId: 'inviter001',
          inviteeId: 'invitee001',
          invitationCode: 'CODE123',
        );

        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        when(mockCollection.doc('invitation001')).thenReturn(mockDocRef);
        when(mockDocRef.set(any)).thenAnswer((_) async {});

        await repository.saveMemberInvitation(memberInvitation);

        verify(mockCollection.doc('invitation001')).called(1);
        verify(
          mockDocRef.set(
            argThat(
              allOf([
                containsPair('inviterId', 'inviter001'),
                containsPair('inviteeId', 'invitee001'),
                containsPair('invitationCode', 'CODE123'),
              ]),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'deleteMemberInvitationがmember_invitations collectionの該当ドキュメントを削除する',
      () async {
        const invitationId = 'invitation001';
        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

        when(mockCollection.doc(invitationId)).thenReturn(mockDocRef);
        when(mockDocRef.delete()).thenAnswer((_) async {});

        await repository.deleteMemberInvitation(invitationId);

        verify(mockCollection.doc(invitationId)).called(1);
        verify(mockDocRef.delete()).called(1);
      },
    );

    test('getByInviteeIdが該当する招待情報を返す', () async {
      const inviteeId = 'invitee001';

      when(
        mockCollection.where('inviteeId', isEqualTo: inviteeId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('invitation001');
      when(mockDoc1.data()).thenReturn({
        'inviterId': 'inviter001',
        'inviteeId': inviteeId,
        'invitationCode': 'CODE123',
      });

      final result = await repository.getByInviteeId(inviteeId);

      expect(result, isNotNull);
      expect(result!.id, 'invitation001');
      expect(result.inviteeId, inviteeId);
      expect(result.invitationCode, 'CODE123');
    });

    test('getByInviteeIdが該当データがない場合nullを返す', () async {
      const inviteeId = 'invitee999';

      when(
        mockCollection.where('inviteeId', isEqualTo: inviteeId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([]);

      final result = await repository.getByInviteeId(inviteeId);

      expect(result, isNull);
    });

    test('getByInvitationCodeが該当する招待情報を返す', () async {
      const invitationCode = 'CODE123';

      when(
        mockCollection.where('invitationCode', isEqualTo: invitationCode),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('invitation001');
      when(mockDoc1.data()).thenReturn({
        'inviterId': 'inviter001',
        'inviteeId': 'invitee001',
        'invitationCode': invitationCode,
      });

      final result = await repository.getByInvitationCode(invitationCode);

      expect(result, isNotNull);
      expect(result!.id, 'invitation001');
      expect(result.invitationCode, invitationCode);
    });

    test('getByInvitationCodeが該当データがない場合nullを返す', () async {
      const invitationCode = 'INVALID';

      when(
        mockCollection.where('invitationCode', isEqualTo: invitationCode),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([]);

      final result = await repository.getByInvitationCode(invitationCode);

      expect(result, isNull);
    });
  });
}
