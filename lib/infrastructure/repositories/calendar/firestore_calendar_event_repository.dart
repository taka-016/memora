import 'package:memora/infrastructure/services/calendar_event_content.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_mapper.dart';
import 'package:memora/infrastructure/services/validate_calendar_recurrence.dart';

class FirestoreCalendarEventRepository implements CalendarEventRepository {
  FirestoreCalendarEventRepository({required this._firestore});
  final FirebaseFirestore _firestore;
  DocumentReference<Map<String, dynamic>> _label(String id) =>
      _firestore.collection('calendar_labels').doc(id);
  Set<String> _references(Map<String, dynamic> data) =>
      (data['referencedLabelIds'] as List? ?? [data['labelId']])
          .cast<String>()
          .toSet();

  Future<void> _adjustLabels(
    Transaction transaction,
    String groupId,
    Set<String> before,
    Set<String> after,
  ) async {
    final snapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final id in {...before, ...after}) {
      final label = await transaction.get(_label(id));
      if (!label.exists || label.data()!['groupId'] != groupId) {
        throw ValidationException('同じグループの色ラベルを指定してください');
      }
      snapshots[id] = label;
    }
    for (final id in snapshots.keys) {
      final delta =
          (after.contains(id) ? 1 : 0) - (before.contains(id) ? 1 : 0);
      if (delta != 0) {
        transaction.update(_label(id), {
          'eventCount': (snapshots[id]!.data()!['eventCount'] as int) + delta,
        });
      }
    }
  }

  @override
  Future<void> replaceCalendarEvent(
    CalendarEvent expected,
    CalendarEvent? replacement,
    CalendarEvent? following, {
    List<CalendarEvent> preservedEvents = const [],
  }) async {
    if (replacement != null &&
            (replacement.id != expected.id ||
                replacement.groupId != expected.groupId) ||
        following != null &&
            (following.id.isNotEmpty ||
                following.groupId != expected.groupId ||
                replacement == null)) {
      throw ValidationException('系列の分割対象が不正です');
    }
    if (preservedEvents.any(
      (value) =>
          value.id.isNotEmpty ||
          value.groupId != expected.groupId ||
          value.recurrenceRule != null,
    )) {
      throw ValidationException('維持する個別予定が不正です');
    }
    if (replacement != null) validateCalendarRecurrence(replacement);
    if (following != null) validateCalendarRecurrence(following);
    final ref = _firestore.collection('calendar_events').doc(expected.id);
    final nextRef = following == null
        ? null
        : _firestore.collection('calendar_events').doc();
    final preservedRefs = preservedEvents
        .map((_) => _firestore.collection('calendar_events').doc())
        .toList();
    final preservedData = preservedEvents
        .map(FirestoreCalendarEventMapper.toCreateFirestore)
        .toList();
    await _firestore.runTransaction<void>((transaction) async {
      final current = await transaction.get(ref);
      if (!current.exists ||
          calendarEventContent(
                CalendarEventMapper.toEntity(
                  FirestoreCalendarEventMapper.fromFirestore(current),
                ),
              ) !=
              calendarEventContent(expected)) {
        throw ValidationException('予定が変更されています。再読み込みしてからやり直してください');
      }
      final before = _references(current.data()!);
      final head = replacement == null
          ? null
          : FirestoreCalendarEventMapper.toUpdateFirestore(replacement);
      final tail = following == null
          ? null
          : FirestoreCalendarEventMapper.toCreateFirestore(following);
      final headRefs = head == null ? <String>{} : _references(head);
      final tailRefs = tail == null ? <String>{} : _references(tail);
      final preservedLabels = preservedData.map(_references).toList();
      final ids = {
        ...before,
        ...headRefs,
        ...tailRefs,
        ...preservedLabels.expand((value) => value),
      };
      final snapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final id in ids) {
        final label = await transaction.get(_label(id));
        if (!label.exists || label.data()!['groupId'] != expected.groupId) {
          throw ValidationException('同じグループの色ラベルを指定してください');
        }
        snapshots[id] = label;
      }
      for (final id in ids) {
        final delta =
            (headRefs.contains(id) ? 1 : 0) +
            (tailRefs.contains(id) ? 1 : 0) +
            preservedLabels.where((value) => value.contains(id)).length -
            (before.contains(id) ? 1 : 0);
        if (delta != 0) {
          transaction.update(_label(id), {
            'eventCount': (snapshots[id]!.data()!['eventCount'] as int) + delta,
          });
        }
      }
      if (head == null) {
        transaction.delete(ref);
      } else {
        transaction.update(ref, head);
      }
      if (tail != null) {
        transaction.set(nextRef!, tail);
      }
      for (var index = 0; index < preservedData.length; index++) {
        transaction.set(preservedRefs[index], preservedData[index]);
      }
    });
  }

  @override
  Future<String> saveCalendarEvent(CalendarEvent event) async {
    validateCalendarRecurrence(event);
    final ref = _firestore.collection('calendar_events').doc();
    final data = FirestoreCalendarEventMapper.toCreateFirestore(event);
    return _firestore.runTransaction((transaction) async {
      await _adjustLabels(transaction, event.groupId, {}, _references(data));
      transaction.set(ref, data);
      return ref.id;
    });
  }

  @override
  Future<void> updateCalendarEvent(CalendarEvent event) async {
    validateCalendarRecurrence(event);
    final ref = _firestore.collection('calendar_events').doc(event.id);
    final data = FirestoreCalendarEventMapper.toUpdateFirestore(event);
    await _firestore.runTransaction<void>((transaction) async {
      final existing = await transaction.get(ref);
      if (!existing.exists || existing.data()!['groupId'] != event.groupId) {
        throw ValidationException('更新する予定のグループは変更できません');
      }
      await _adjustLabels(
        transaction,
        event.groupId,
        _references(existing.data()!),
        _references(data),
      );
      transaction.update(ref, data);
    });
  }

  @override
  Future<void> deleteCalendarEvent(String eventId) async {
    final ref = _firestore.collection('calendar_events').doc(eventId);
    await _firestore.runTransaction<void>((transaction) async {
      final existing = await transaction.get(ref);
      if (!existing.exists) return;
      await _adjustLabels(
        transaction,
        existing.data()!['groupId'] as String,
        _references(existing.data()!),
        {},
      );
      transaction.delete(ref);
    });
  }
}
