import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/calendar_override_mapper.dart';
import 'package:memora/infrastructure/services/validate_calendar_recurrence.dart';
import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/calendar/sqlite_calendar_event_mapper.dart';

class SqliteCalendarEventRepository implements CalendarEventRepository {
  SqliteCalendarEventRepository(this.db);
  final OfflineDatabase db;

  Future<void> _validateLabel(CalendarEvent event) async {
    validateCalendarRecurrence(event);
    for (final id in {
      event.labelId,
      ...event.overrides.where((v) => !v.isCancelled).map((v) => v.labelId!),
    }) {
      final labels = await db.rows(
        'calendar_labels',
        where: 'id = ? AND group_id = ?',
        args: [id, event.groupId],
      );
      if (labels.isEmpty) throw ValidationException('同じグループの色ラベルを指定してください');
    }
  }

  @override
  Future<void> replaceCalendarEvent(
    CalendarEvent expected,
    CalendarEvent? replacement,
    CalendarEvent? following,
  ) => db.transaction(() async {
    final rows = await db.rows('calendar_events', where: 'id = ?', args: [expected.id]);
    final overrides = await db.rows('calendar_event_overrides', where: 'event_id = ?', args: [expected.id]);
    final current = rows.isEmpty ? null : SqliteCalendarEventMapper.fromRow(rows.single, overrides: overrides.map((row) => CalendarOverrideMapper.fromRow(row, expected.isAllDay)).toList());
    if (current == null || CalendarEventMapper.toEntity(current) != expected)
      throw ValidationException('予定が変更されています。再読み込みしてからやり直してください');
    if (replacement != null &&
            (replacement.id != expected.id ||
                replacement.groupId != expected.groupId) ||
        following != null &&
            (following.id.isNotEmpty || following.groupId != expected.groupId))
      throw ValidationException('系列の分割対象が不正です');
    if (replacement != null) await _validateLabel(replacement);
    if (following != null) await _validateLabel(following);
    if (replacement == null) {
      await deleteCalendarEvent(expected.id);
    } else {
      await updateCalendarEvent(replacement);
    }
    if (following != null) await saveCalendarEvent(following);
  });

  @override
  Future<String> saveCalendarEvent(CalendarEvent event) =>
      db.transaction(() async {
        await _validateLabel(event);
        final id = const Uuid().v4();
        await db.insertRow(
          'calendar_events',
          SqliteCalendarEventMapper.toRow(event.copyWith(id: id)),
        );
        await _saveOverrides(event.copyWith(id: id));
        return id;
      });

  @override
  Future<void> updateCalendarEvent(CalendarEvent event) =>
      db.transaction(() async {
        await _validateLabel(event);
        final existing = await db.rows(
          'calendar_events',
          where: 'id = ?',
          args: [event.id],
        );
        if (existing.isEmpty || existing.single['group_id'] != event.groupId) {
          throw ValidationException('更新する予定のグループは変更できません');
        }
        await db.updateRow(
          'calendar_events',
          event.id,
          SqliteCalendarEventMapper.toRow(event),
        );
        await _saveOverrides(event);
      });

  Future<void> _saveOverrides(CalendarEvent event) async {
    await db.deleteRows('calendar_event_overrides', 'event_id', event.id);
    for (final value in event.overrides) {
      await db.insertRow(
        'calendar_event_overrides',
        CalendarOverrideMapper.toRow(
          value,
          event.id,
          event.groupId,
          event.isAllDay,
        ),
      );
    }
  }

  @override
  Future<void> deleteCalendarEvent(String eventId) =>
      db.deleteRows('calendar_events', 'id', eventId);
}
