import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/calendar/calendar_label.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_label_repository.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_label_mapper.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreCalendarLabelRepository implements CalendarLabelRepository {
  FirestoreCalendarLabelRepository({required this._firestore});
  final FirebaseFirestore _firestore;

  @override
  Future<String> saveCalendarLabel(CalendarLabel label) async {
    final collection = _firestore.collection('calendar_labels');
    if (label.id.isEmpty) {
      final ref = await collection.add({
        ...FirestoreCalendarLabelMapper.toCreateFirestore(label),
        'eventCount': 0,
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
  Future<void> reorderCalendarLabels(
    String groupId,
    List<String> labelIds,
  ) async {
    final refs = labelIds
        .map((id) => _firestore.collection('calendar_labels').doc(id))
        .toList();
    await _firestore.runTransaction<void>((transaction) async {
      for (final ref in refs) {
        final existing = await transaction.get(ref);
        if (!existing.exists || existing.data()!['groupId'] != groupId) {
          throw ValidationException('同じグループの色ラベルを指定してください');
        }
      }
      for (var index = 0; index < refs.length; index++) {
        transaction.update(refs[index], <String, dynamic>{
          'sortOrder': index,
          ...FirestoreWriteMetadata.forUpdate(),
        });
      }
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
