import 'package:memora/infrastructure/repositories/calendar/firestore_calendar_event_repository.dart';
import 'package:memora/infrastructure/repositories/calendar/firestore_calendar_label_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group/group_member.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_mapper.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_member_mapper.dart';

class FirestoreGroupRepository implements GroupRepository {
  final FirebaseFirestore _firestore;

  FirestoreGroupRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> saveGroup(Group group) async {
    final batch = _firestore.batch();

    final groupDocRef = _firestore.collection('groups').doc();
    batch.set(groupDocRef, FirestoreGroupMapper.toCreateFirestore(group));

    for (final GroupMember member in group.members) {
      final memberDocRef = _firestore.collection('group_members').doc();
      batch.set(
        memberDocRef,
        FirestoreGroupMemberMapper.toCreateFirestore(
          member.copyWith(groupId: groupDocRef.id),
        ),
      );
    }

    await batch.commit();
    return groupDocRef.id;
  }

  @override
  Future<void> updateGroup(Group group) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('groups').doc(group.id),
      FirestoreGroupMapper.toUpdateFirestore(group),
    );

    final memberSnapshot = await _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: group.id)
        .get();
    for (final doc in memberSnapshot.docs) {
      batch.delete(doc.reference);
    }

    for (final GroupMember member in group.members) {
      final memberDocRef = _firestore.collection('group_members').doc();
      batch.set(
        memberDocRef,
        FirestoreGroupMemberMapper.toCreateFirestore(
          member.copyWith(groupId: group.id),
        ),
      );
    }

    await batch.commit();
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'calendarDeleting': true,
    });
    final events = await _firestore
        .collection('calendar_events')
        .where('groupId', isEqualTo: groupId)
        .get();
    final eventRepository = FirestoreCalendarEventRepository(
      firestore: _firestore,
    );
    for (final event in events.docs) {
      await eventRepository.deleteCalendarEvent(event.id);
    }
    final labels = await _firestore
        .collection('calendar_labels')
        .where('groupId', isEqualTo: groupId)
        .get();
    final labelRepository = FirestoreCalendarLabelRepository(
      firestore: _firestore,
      ensureMembership: (_) async {},
    );
    for (final label in labels.docs) {
      await labelRepository.deleteCalendarLabel(label.id);
    }
    final batch = _firestore.batch();

    final memberSnapshot = await _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: groupId)
        .get();
    for (final doc in memberSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_firestore.collection('groups').doc(groupId));
    await batch.commit();
  }

  @override
  Future<void> deleteGroupMembersByMemberId(String memberId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('group_members')
        .where('memberId', isEqualTo: memberId)
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
