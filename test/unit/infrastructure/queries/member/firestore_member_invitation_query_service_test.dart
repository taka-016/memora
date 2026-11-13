import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/infrastructure/queries/member/firestore_member_invitation_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_member_invitation_query_service_test.mocks.dart';

@GenerateMocks([
  DocumentReference,
  DocumentSnapshot,
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  group('FirestoreMemberInvitationQueryService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockInvitationCollection;
    late FirestoreMemberInvitationQueryService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockInvitationCollection =
          MockCollectionReference<Map<String, dynamic>>();
      when(mockFirestore.collection('member_invitations'))
          .thenReturn(mockInvitationCollection);
      service = FirestoreMemberInvitationQueryService(firestore: mockFirestore, accountId: () => 'uid');
    });

    test('同じ対象の全招待をIDと期待バージョン付きで返す', () async {
      final query = MockQuery<Map<String, dynamic>>();
      final snapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final docs = [
        for (var index = 0; index < 2; index++)
          MockQueryDocumentSnapshot<Map<String, dynamic>>(),
      ];
      when(mockInvitationCollection.where('inviteeId', isEqualTo: 'm'))
          .thenReturn(query);
      when(query.get()).thenAnswer((_) async => snapshot);
      when(snapshot.docs).thenReturn(docs);
      for (var index = 0; index < docs.length; index++) {
        when(docs[index].id).thenReturn(index == 0 ? 'i' : 'j');
        when(docs[index].data()).thenReturn({
          'inviteeId': 'm',
          'invitationCode': 'code$index',
          'version': index + 2,
        });
      }
      final result = await service.getAllByInviteeId('m');
      expect(result.map((i) => '${i.id}:${i.version}'), ['i:2', 'j:3']);
    });

    test('inviteeIdで招待情報を取得する', () async {
      const inviteeId = 'invitee001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockInvitationCollection.where('inviteeId', isEqualTo: inviteeId))
          .thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('invitation123');
      when(mockDoc.data()).thenReturn({
        'inviteeId': inviteeId,
        'inviterId': 'inviter001',
        'invitationCode': 'CODE123',
      });

      final result = await service.getByInviteeId(inviteeId);

      expect(result, isNotNull);
      expect(result, isA<MemberInvitationDto>());
      expect(result!.invitationCode, 'CODE123');
    });

    test('inviteeIdで該当なしの場合はnullを返す', () async {
      const inviteeId = 'invitee404';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(mockInvitationCollection.where('inviteeId', isEqualTo: inviteeId))
          .thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([]);

      final result = await service.getByInviteeId(inviteeId);

      expect(result, isNull);
    });

    test('inviteeId取得時に例外が発生した場合は取得失敗を伝える', () async {
      when(
        mockInvitationCollection.where(any, isEqualTo: anyNamed('isEqualTo')),
      ).thenThrow(TestException('Firestore error'));

      await expectLater(
        service.getByInviteeId('invitee001'),
        throwsA(isA<TestException>()),
      );
    });

    test('招待コードの文書を単一取得し本人の受理処理へ紐付ける', () async {
      final ref = MockDocumentReference<Map<String, dynamic>>();
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      final claims = MockCollectionReference<Map<String, dynamic>>();
      final claim = MockDocumentReference<Map<String, dynamic>>();
      when(mockInvitationCollection.doc('CODE')).thenReturn(ref);
      when(ref.get()).thenAnswer((_) async => doc);
      when(doc.exists).thenReturn(true);
      when(doc.id).thenReturn('CODE');
      when(doc.data()).thenReturn({'inviteeId': 'm', 'inviterId': 'owner', 'invitationCode': 'CODE', 'version': 2});
      when(mockFirestore.collection('member_invitation_claims')).thenReturn(claims);
      when(claims.doc('uid')).thenReturn(claim);
      when(claim.set(any)).thenAnswer((_) async {});
      expect((await service.getByInvitationCode('CODE'))?.inviteeId, 'm');
      verify(claim.set({'code': 'CODE'})).called(1);
      verifyNever(mockInvitationCollection.where('invitationCode', isEqualTo: anyNamed('isEqualTo')));
    });

    test('招待コードが存在しなければ受理処理へ紐付けない', () async {
      final ref = MockDocumentReference<Map<String, dynamic>>();
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockInvitationCollection.doc('missing')).thenReturn(ref);
      when(ref.get()).thenAnswer((_) async => doc);
      when(doc.exists).thenReturn(false);
      expect(await service.getByInvitationCode('missing'), isNull);
      verifyNever(mockFirestore.collection('member_invitation_claims'));
    });
  });
}
