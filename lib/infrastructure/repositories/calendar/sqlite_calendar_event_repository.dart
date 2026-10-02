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
    final labels = await db.rows(
      'calendar_labels',
      where: 'id = ? AND group_id = ?',
      args: [event.labelId, event.groupId],
    );
    if (labels.isEmpty) throw ValidationException('同じグループの色ラベルを指定してください');
  }

  @override
  Future<String> saveCalendarEvent(CalendarEvent event) =>
      db.transaction(() async {
        await _validateLabel(event);
        final id = const Uuid().v4();
        await db.insertRow(
          'calendar_events',
          SqliteCalendarEventMapper.toRow(event.copyWith(id: id)),
        );
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
        if (existing.isEmpty || existing.single['group_id'] != event.groupId)
          throw ValidationException('更新する予定のグループは変更できません');
        await db.updateRow(
          'calendar_events',
          event.id,
          SqliteCalendarEventMapper.toRow(event),
        );
      });

  @override
  Future<void> deleteCalendarEvent(String eventId) =>
      db.deleteRows('calendar_events', 'id', eventId);
}
