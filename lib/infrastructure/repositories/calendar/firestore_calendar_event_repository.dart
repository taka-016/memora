import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_mapper.dart';

class FirestoreCalendarEventRepository implements CalendarEventRepository {
  FirestoreCalendarEventRepository({
    required FirebaseFirestore firestore,
    Future<void> Function(String)? ensureMembership,
  }) : _firestore = firestore,
       _ensureMembership = ensureMembership;
  final FirebaseFirestore _firestore;
  final Future<void> Function(String)? _ensureMembership;

  DocumentReference<Map<String, dynamic>> _label(String id) =>
      _firestore.collection('calendar_labels').doc(id);
  void _validateLabel(
    DocumentSnapshot<Map<String, dynamic>> label,
    String groupId,
  ) {
    if (!label.exists || label.data()!['groupId'] != groupId) {
      throw ValidationException('同じグループの色ラベルを指定してください');
    }
  }

  void _adjust(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> labelRef,
    DocumentSnapshot<Map<String, dynamic>> label,
    String eventId,
    int delta,
  ) {
    transaction.update(labelRef, {
      'eventCount': (label.data()!['eventCount'] as int) + delta,
      'lastEventId': eventId,
    });
  }

  @override
  Future<String> saveCalendarEvent(CalendarEvent event) async {
    await _ensureMembership?.call(event.groupId);
    final ref = _firestore.collection('calendar_events').doc();
    return _firestore.runTransaction((transaction) async {
      final label = await transaction.get(_label(event.labelId));
      _validateLabel(label, event.groupId);
      _adjust(transaction, _label(event.labelId), label, ref.id, 1);
      transaction.set(
        ref,
        FirestoreCalendarEventMapper.toCreateFirestore(event),
      );
      return ref.id;
    });
  }

  @override
  Future<void> updateCalendarEvent(CalendarEvent event) async {
    await _ensureMembership?.call(event.groupId);
    final ref = _firestore.collection('calendar_events').doc(event.id);
    await _firestore.runTransaction<void>((transaction) async {
      final existing = await transaction.get(ref);
      if (!existing.exists || existing.data()!['groupId'] != event.groupId) {
        throw ValidationException('更新する予定のグループは変更できません');
      }
      final label = await transaction.get(_label(event.labelId));
      _validateLabel(label, event.groupId);
      final oldLabelId = existing.data()!['labelId'] as String;
      if (oldLabelId != event.labelId) {
        final oldLabel = await transaction.get(_label(oldLabelId));
        _adjust(transaction, _label(oldLabelId), oldLabel, event.id, -1);
        _adjust(transaction, _label(event.labelId), label, event.id, 1);
      }
      transaction.update(
        ref,
        FirestoreCalendarEventMapper.toUpdateFirestore(event),
      );
    });
  }

  @override
  Future<void> deleteCalendarEvent(String eventId) async {
    final ref = _firestore.collection('calendar_events').doc(eventId);
    await _firestore.runTransaction<void>((transaction) async {
      final existing = await transaction.get(ref);
      if (!existing.exists) return;
      final label = await transaction.get(
        _label(existing.data()!['labelId'] as String),
      );
      _adjust(
        transaction,
        _label(existing.data()!['labelId'] as String),
        label,
        eventId,
        -1,
      );
      transaction.delete(ref);
    });
  }
}
