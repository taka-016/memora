import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/repositories/member/member_event_repository.dart';
import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_event_mapper.dart';
import 'package:memora/infrastructure/services/firestore_version_check.dart';

class FirestoreMemberEventRepository implements MemberEventRepository {
  final FirebaseFirestore _firestore;

  FirestoreMemberEventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> saveMemberEvent(MemberEvent memberEvent) async {
    final collection = _firestore.collection('member_events');
    final docId = '${Uri.encodeComponent(memberEvent.memberId)}_${memberEvent.year}';
    final target = collection.doc(docId);
    final snapshot = await collection
        .where('memberId', isEqualTo: memberEvent.memberId)
        .where('year', isEqualTo: memberEvent.year)
        .get();
    final duplicates = {
      for (final doc in snapshot.docs)
        if (doc.id != docId) doc.id: doc.data()['version'] as int?,
    };
    await _firestore.runTransaction<void>((transaction) async {
      final current = await transaction.get(target);
      if (memberEvent.id == docId) {
        FirestoreVersionCheck.requireMatch(current.data(), memberEvent.version);
      } else {
        FirestoreVersionCheck.requireAbsent(current.data());
        if (memberEvent.id.isNotEmpty) {
          final original = await transaction.get(collection.doc(memberEvent.id));
          FirestoreVersionCheck.requireMatch(original.data(), memberEvent.version);
        }
      }
      if (memberEvent.memo.isEmpty) {
        for (final entry in duplicates.entries) {
          final duplicate = await transaction.get(collection.doc(entry.key));
          FirestoreVersionCheck.requireMatch(
            duplicate.data(),
            entry.key == memberEvent.id ? memberEvent.version : entry.value,
          );
        }
        if (current.exists) transaction.delete(target);
        for (final id in duplicates.keys) {
          transaction.delete(collection.doc(id));
        }
      } else if (memberEvent.id == docId) {
        transaction.update(target, FirestoreMemberEventMapper.toUpdateFirestore(memberEvent));
      } else {
        transaction.set(target, FirestoreMemberEventMapper.toCreateFirestore(memberEvent));
      }
    });
    if (memberEvent.memo.isEmpty) return '';
    if (duplicates.isNotEmpty) {
      await _firestore.runTransaction<void>((transaction) async {
        for (final entry in duplicates.entries) {
          final duplicate = await transaction.get(collection.doc(entry.key));
          FirestoreVersionCheck.requireMatch(
            duplicate.data(),
            entry.key == memberEvent.id ? memberEvent.version : entry.value,
          );
        }
        for (final id in duplicates.keys) {
          transaction.delete(collection.doc(id));
        }
      });
    }
    return docId;
  }

  @override
  Future<void> deleteMemberEvent(String memberEventId, {int? expectedVersion}) async {
    await FirestoreVersionCheck.delete(
      _firestore, _firestore.collection('member_events').doc(memberEventId), expectedVersion,
    );
  }

  @override
  Future<void> deleteMemberEventsByMemberId(String memberId) async {
    final snapshot = await _firestore.collection('member_events').where('memberId', isEqualTo: memberId).get();
    final expected = {for (final doc in snapshot.docs) doc.id: doc.data()['version'] as int?};
    await _firestore.runTransaction<void>((transaction) async {
      for (final entry in expected.entries) {
        final current = await transaction.get(_firestore.collection('member_events').doc(entry.key));
        FirestoreVersionCheck.requireMatch(current.data(), entry.value);
      }
      for (final id in expected.keys) { transaction.delete(_firestore.collection('member_events').doc(id)); }
    });
  }
}
