import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/infrastructure/mappers/firestore_member_mapper.dart';

class FirestoreMemberRepository implements MemberRepository {
  final FirebaseFirestore _firestore;

  FirestoreMemberRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveMember(Member member) async {
    await _firestore
        .collection('members')
        .add(FirestoreMemberMapper.toFirestore(member));
  }

  @override
  Future<void> updateMember(Member member) async {
    await _firestore
        .collection('members')
        .doc(member.id)
        .update(FirestoreMemberMapper.toFirestore(member));
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await _firestore.collection('members').doc(memberId).delete();
  }
}
