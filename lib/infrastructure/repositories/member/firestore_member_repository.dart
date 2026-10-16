import 'package:memora/infrastructure/repositories/firestore_write_context.dart';
import 'package:memora/infrastructure/services/firestore_deleted_parent_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_mapper.dart';

class FirestoreMemberRepository implements MemberRepository {
  final FirebaseFirestore _firestore;

  FirestoreMemberRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveMember(Member member) async {
    await _firestore
        .collection('members')
        .add(FirestoreMemberMapper.toCreateFirestore(member));
  }

  @override
  Future<void> updateMember(Member member) async {
    await _firestore
        .collection('members')
        .doc(member.id)
        .update(FirestoreMemberMapper.toUpdateFirestore(member));
  }

  @override
  Future<void> deleteMember(String memberId) async {
    final source = _firestore.collection('members').doc(memberId);
    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(source);
      final data = snapshot.data();
      if (data == null) return;
      final context = FirestoreTransactionWriteContext(
        firestore: _firestore,
        transaction: transaction,
      );
      FirestoreDeletedParentStore(context).saveMember(memberId, data);
      context.delete(source);
    });
  }
}
