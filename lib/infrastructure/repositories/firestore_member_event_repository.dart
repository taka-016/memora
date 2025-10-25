import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/repositories/member_event_repository.dart';
import 'package:memora/domain/entities/member_event.dart';
import 'package:memora/infrastructure/mappers/firestore_member_event_mapper.dart';

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
  Future<void> deleteMemberEvent(String memberEventId) async {
    await _firestore.collection('member_events').doc(memberEventId).delete();
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
