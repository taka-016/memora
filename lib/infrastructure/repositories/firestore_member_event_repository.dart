import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/member_event_repository.dart';
import '../../domain/entities/member_event.dart';
import '../mappers/firestore_member_event_mapper.dart';

class FirestoreMemberEventRepository implements MemberEventRepository {
  final FirebaseFirestore _firestore;

  FirestoreMemberEventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveMemberEvent(MemberEvent memberEvent) async {
    await _firestore
        .collection('member_events')
        .add(FirestoreMemberEventMapper.toFirestore(memberEvent));
  }

  @override
  Future<List<MemberEvent>> getMemberEvents() async {
    try {
      final snapshot = await _firestore.collection('member_events').get();
      return snapshot.docs
          .map((doc) => FirestoreMemberEventMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deleteMemberEvent(String memberEventId) async {
    await _firestore.collection('member_events').doc(memberEventId).delete();
  }

  @override
  Future<List<MemberEvent>> getMemberEventsByMemberId(String memberId) async {
    try {
      final snapshot = await _firestore
          .collection('member_events')
          .where('memberId', isEqualTo: memberId)
          .get();
      return snapshot.docs
          .map((doc) => FirestoreMemberEventMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deleteMemberEventsByMemberId(String memberId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('member_events')
        .where('memberId', isEqualTo: memberId)
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
