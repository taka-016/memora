import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/calendar/calendar_label.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_label_repository.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_label_mapper.dart';

class FirestoreCalendarLabelRepository implements CalendarLabelRepository {
  FirestoreCalendarLabelRepository({
    required FirebaseFirestore firestore,
    required Future<void> Function(String) ensureMembership,
  }) : _firestore = firestore,
       _ensureMembership = ensureMembership;
  final FirebaseFirestore _firestore;
  final Future<void> Function(String) _ensureMembership;

  @override
  Future<String> saveCalendarLabel(CalendarLabel label) async {
    await _ensureMembership(label.groupId);
    final collection = _firestore.collection('calendar_labels');
    if (label.id.isEmpty) {
      final ref = await collection.add({
        ...FirestoreCalendarLabelMapper.toCreateFirestore(label),
        'eventCount': 0,
        'lastEventId': null,
      });
      return ref.id;
    }
    final ref = collection.doc(label.id);
    return _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (!existing.exists || existing.data()!['groupId'] != label.groupId) {
        throw ValidationException('更新する色ラベルのグループは変更できません');
      }
      transaction.update(
        ref,
        FirestoreCalendarLabelMapper.toUpdateFirestore(label),
      );
      return label.id;
    });
  }

  @override
  Future<void> deleteCalendarLabel(String labelId) async {
    final ref = _firestore.collection('calendar_labels').doc(labelId);
    await _firestore.runTransaction<void>((transaction) async {
      final existing = await transaction.get(ref);
      if (!existing.exists) return;
      if (existing.data()!['eventCount'] != 0) {
        throw ValidationException('使用中の色ラベルは削除できません');
      }
      transaction.delete(ref);
    });
  }
}
