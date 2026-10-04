import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_mapper.dart';
import 'package:memora/infrastructure/services/validate_calendar_recurrence.dart';

class FirestoreCalendarEventRepository implements CalendarEventRepository {
  FirestoreCalendarEventRepository({
    required this._firestore,
    this._ensureMembership,
  });
  final FirebaseFirestore _firestore;
  final Future<void> Function(String)? _ensureMembership;
  DocumentReference<Map<String, dynamic>> _label(String id) =>
      _firestore.collection('calendar_labels').doc(id);
  Set<String> _references(Map<String, dynamic> data) =>
      (data['referencedLabelIds'] as List? ?? [data['labelId']])
          .cast<String>()
          .toSet();

  Future<void> _adjustLabels(
    Transaction transaction,
    String groupId,
    String eventId,
    Set<String> before,
    Set<String> after,
  ) async {
    if ({...before, ...after}.length > 3) {
      throw ValidationException('オンラインの系列は変更前後を合わせて色ラベル3種類まで一括保存できます');
    }
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
          'lastEventId': eventId,
        });
      }
    }
  }

  @override
  Future<void> replaceCalendarEvent(
    CalendarEvent expected,
    CalendarEvent? replacement,
    CalendarEvent? following,
  ) async {
    if (replacement != null &&
            (replacement.id != expected.id ||
                replacement.groupId != expected.groupId) ||
        following != null &&
            (following.id.isNotEmpty ||
                following.groupId != expected.groupId ||
                replacement == null))
      throw ValidationException('系列の分割対象が不正です');
    if (replacement != null) validateCalendarRecurrence(replacement);
    if (following != null) validateCalendarRecurrence(following);
    await _ensureMembership?.call(expected.groupId);
    final ref = _firestore.collection('calendar_events').doc(expected.id);
    final nextRef = following == null
        ? null
        : _firestore.collection('calendar_events').doc();
    await _firestore.runTransaction<void>((transaction) async {
      final current = await transaction.get(ref);
      if (!current.exists ||
          CalendarEventMapper.toEntity(
                FirestoreCalendarEventMapper.fromFirestore(current),
              ) !=
              expected)
        throw ValidationException('予定が変更されています。再読み込みしてからやり直してください');
      final before = _references(current.data()!);
      final head = replacement == null
          ? null
          : FirestoreCalendarEventMapper.toUpdateFirestore(replacement);
      final tail = following == null
          ? null
          : FirestoreCalendarEventMapper.toCreateFirestore(following);
      final headRefs = head == null ? <String>{} : _references(head);
      final tailRefs = tail == null ? <String>{} : _references(tail);
      final ids = {...before, ...headRefs, ...tailRefs};
      if (ids.length > 3)
        throw ValidationException('オンラインの系列は変更前後を合わせて色ラベル3種類まで一括保存できます');
      final snapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final id in ids) {
        final label = await transaction.get(_label(id));
        if (!label.exists || label.data()!['groupId'] != expected.groupId)
          throw ValidationException('同じグループの色ラベルを指定してください');
        snapshots[id] = label;
      }
      for (final id in ids) {
        final delta =
            (headRefs.contains(id) ? 1 : 0) +
            (tailRefs.contains(id) ? 1 : 0) -
            (before.contains(id) ? 1 : 0);
        if (delta != 0)
          transaction.update(_label(id), {
            'eventCount': (snapshots[id]!.data()!['eventCount'] as int) + delta,
            'lastEventId': expected.id,
          });
      }
      if (head == null) {
        transaction.delete(ref);
      } else {
        transaction.update(ref, {...head, 'splitEventId': nextRef?.id});
      }
      if (tail != null)
        transaction.set(nextRef!, {...tail, 'splitFromEventId': expected.id});
    });
  }

  @override
  Future<String> saveCalendarEvent(CalendarEvent event) async {
    validateCalendarRecurrence(event);
    if ({
          event.labelId,
          ...event.overrides
              .where((v) => !v.isCancelled)
              .map((v) => v.labelId!),
        }.length >
        3) {
      throw ValidationException('オンラインの1系列に指定できる色ラベルは3種類までです');
    }
    await _ensureMembership?.call(event.groupId);
    final ref = _firestore.collection('calendar_events').doc();
    final data = FirestoreCalendarEventMapper.toCreateFirestore(event);
    return _firestore.runTransaction((transaction) async {
      await _adjustLabels(
        transaction,
        event.groupId,
        ref.id,
        {},
        _references(data),
      );
      transaction.set(ref, data);
      return ref.id;
    });
  }

  @override
  Future<void> updateCalendarEvent(CalendarEvent event) async {
    validateCalendarRecurrence(event);
    if ({
          event.labelId,
          ...event.overrides
              .where((v) => !v.isCancelled)
              .map((v) => v.labelId!),
        }.length >
        3) {
      throw ValidationException('オンラインの1系列に指定できる色ラベルは3種類までです');
    }
    await _ensureMembership?.call(event.groupId);
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
        event.id,
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
        eventId,
        _references(existing.data()!),
        {},
      );
      transaction.delete(ref);
    });
  }
}
