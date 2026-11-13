import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_invitation_repository.dart';
import '../../../../helpers/firestore_transaction_store.dart';

void main() {
  test('招待はコードを文書IDとして初回作成する', () async {
    final store = FirestoreTransactionStore();
    final repo = FirestoreMemberInvitationRepository(firestore: store.firestore);
    await repo.saveMemberInvitation(const MemberInvitation(id: '', inviterId: 'owner', inviteeId: 'm', invitationCode: 'CODE'));
    expect(store.rows['member_invitations/CODE']!['version'], 1);
  });
  test('再発行は旧招待の競合を確認して新コードと入れ替える', () async {
    final store = FirestoreTransactionStore();
    store.rows['member_invitations/OLD'] = {'version': 2, 'inviteeId': 'm', 'invitationCode': 'OLD'};
    final repo = FirestoreMemberInvitationRepository(firestore: store.firestore);
    const updated = MemberInvitation(id: 'OLD', version: 2, inviterId: 'owner', inviteeId: 'm', invitationCode: 'NEW');
    await repo.updateMemberInvitation(updated);
    expect(store.rows.containsKey('member_invitations/OLD'), false);
    expect(store.rows['member_invitations/NEW']!['version'], 1);
    await expectLater(repo.updateMemberInvitation(updated), throwsA(isA<FirebaseException>()));
    expect(store.commits, 1);
  });
}
