import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/member_repository.dart';
import '../../domain/entities/member.dart';
import '../mappers/firestore_member_mapper.dart';

class FirestoreMemberRepository implements MemberRepository {
  final FirebaseFirestore _firestore;

  FirestoreMemberRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveMember(Member member) async {
    await _firestore
        .collection('members')
        .doc(member.id)
        .set(FirestoreMemberMapper.toFirestore(member));
  }

  @override
  Future<void> updateMember(Member member) async {
    await _firestore
        .collection('members')
        .doc(member.id)
        .update(FirestoreMemberMapper.toFirestore(member));
  }

  @override
  Future<List<Member>> getMembers() async {
    try {
      final snapshot = await _firestore.collection('members').get();
      return snapshot.docs
          .map((doc) => FirestoreMemberMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await _firestore.collection('members').doc(memberId).delete();
  }

  @override
  Future<Member?> getMemberById(String memberId) async {
    try {
      final doc = await _firestore.collection('members').doc(memberId).get();
      if (doc.exists) {
        return FirestoreMemberMapper.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Member?> getMemberByAccountId(String accountId) async {
    try {
      final querySnapshot = await _firestore
          .collection('members')
          .where('accountId', isEqualTo: accountId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return FirestoreMemberMapper.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Member>> getMembersByAdministratorId(
    String administratorId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('members')
          .where('administratorId', isEqualTo: administratorId)
          .get();

      return querySnapshot.docs
          .map((doc) => FirestoreMemberMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
