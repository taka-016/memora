import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/managed_member_repository.dart';
import '../../domain/entities/managed_member.dart';
import '../mappers/firestore_managed_member_mapper.dart';

class FirestoreManagedMemberRepository implements ManagedMemberRepository {
  final FirebaseFirestore _firestore;

  FirestoreManagedMemberRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveManagedMember(ManagedMember managedMember) async {
    await _firestore.collection('managed_members').add(
      FirestoreManagedMemberMapper.toFirestore(managedMember),
    );
  }

  @override
  Future<List<ManagedMember>> getManagedMembers() async {
    try {
      final snapshot = await _firestore.collection('managed_members').get();
      return snapshot.docs
          .map((doc) => FirestoreManagedMemberMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deleteManagedMember(String managedMemberId) async {
    await _firestore.collection('managed_members').doc(managedMemberId).delete();
  }

  @override
  Future<List<ManagedMember>> getManagedMembersByMemberId(String memberId) async {
    try {
      final snapshot = await _firestore
          .collection('managed_members')
          .where('memberId', isEqualTo: memberId)
          .get();
      return snapshot.docs
          .map((doc) => FirestoreManagedMemberMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<ManagedMember>> getManagedMembersByManagedMemberId(String managedMemberId) async {
    try {
      final snapshot = await _firestore
          .collection('managed_members')
          .where('managedMemberId', isEqualTo: managedMemberId)
          .get();
      return snapshot.docs
          .map((doc) => FirestoreManagedMemberMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
}