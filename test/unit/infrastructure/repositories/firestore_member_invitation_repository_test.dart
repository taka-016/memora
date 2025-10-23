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

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
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
      'updateMemberInvitationがmember_invitations collectionのドキュメントを更新する（更新）',
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

        await repository.updateMemberInvitation(memberInvitation);

        verify(mockCollection.doc('invitation001')).called(1);
        verify(
          mockDocRef.update(
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
  });
}
