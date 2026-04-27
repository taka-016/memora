import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/repositories/member/member_event_repository.dart';
import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_event_mapper.dart';

class FirestoreMemberEventRepository implements MemberEventRepository {
  final FirebaseFirestore _firestore;

  FirestoreMemberEventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> saveMemberEvent(MemberEvent memberEvent) async {
    final collection = _firestore.collection('member_events');
    final docId = _memberEventDocId(memberEvent);
    final docRef = collection.doc(docId);
    final snapshot = await collection
        .where('memberId', isEqualTo: memberEvent.memberId)
        .where('year', isEqualTo: memberEvent.year)
        .get();

    if (memberEvent.memo.isEmpty) {
      await _deleteMemberEventDocs(snapshot.docs);
      return '';
    }

    final existingDocIds = snapshot.docs.map((doc) => doc.id).toSet();
    final firestoreData = existingDocIds.contains(docId)
        ? FirestoreMemberEventMapper.toUpdateFirestore(memberEvent)
        : FirestoreMemberEventMapper.toCreateFirestore(memberEvent);

    await docRef.set(firestoreData, SetOptions(merge: true));
    await _deleteDuplicateDocs(snapshot.docs, docId);
    return docId;
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

  String _memberEventDocId(MemberEvent memberEvent) {
    final memberId = Uri.encodeComponent(memberEvent.memberId);
    return '${memberId}_${memberEvent.year}';
  }

  Future<void> _deleteDuplicateDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String docId,
  ) async {
    final duplicateDocs = docs.where((doc) => doc.id != docId).toList();
    if (duplicateDocs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in duplicateDocs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _deleteMemberEventDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
