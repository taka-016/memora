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
      transaction.set(
        _firestore.collection('deleted_members').doc(memberId),
        data,
      );
      transaction.delete(source);
    });
  }
}
