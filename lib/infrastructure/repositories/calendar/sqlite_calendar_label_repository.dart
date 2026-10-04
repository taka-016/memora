import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/calendar/calendar_label.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_label_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/calendar/sqlite_calendar_label_mapper.dart';

class SqliteCalendarLabelRepository implements CalendarLabelRepository {
  SqliteCalendarLabelRepository(this.db);
  final OfflineDatabase db;

  @override
  Future<String> saveCalendarLabel(CalendarLabel label) =>
      db.transaction(() async {
        if (label.id.isEmpty) {
          final id = const Uuid().v4();
          await db.insertRow(
            'calendar_labels',
            SqliteCalendarLabelMapper.toRow(label.copyWith(id: id)),
          );
          return id;
        }
        final existing = await db.rows(
          'calendar_labels',
          where: 'id = ?',
          args: [label.id],
        );
        if (existing.isEmpty || existing.single['group_id'] != label.groupId) {
          throw ValidationException('更新する色ラベルのグループは変更できません');
        }
        await db.updateRow(
          'calendar_labels',
          label.id,
          SqliteCalendarLabelMapper.toRow(label),
        );
        return label.id;
      });

  @override
  Future<void> reorderCalendarLabels(String groupId, List<String> labelIds) =>
      db.transaction(() async {
        for (var index = 0; index < labelIds.length; index++) {
          final rows = await db.rows(
            'calendar_labels',
            where: 'id = ?',
            args: [labelIds[index]],
          );
          if (rows.isEmpty || rows.single['group_id'] != groupId) {
            throw ValidationException('同じグループの色ラベルを指定してください');
          }
          await db.updateRow('calendar_labels', labelIds[index], {
            'sort_order': index,
          });
        }
      });

  @override
  Future<void> deleteCalendarLabel(String labelId) => db.transaction(() async {
    if ((await db.rows(
          'calendar_events',
          where: 'label_id = ?',
          args: [labelId],
        )).isNotEmpty ||
        (await db.rows(
          'calendar_event_overrides',
          where: 'label_id = ?',
          args: [labelId],
        )).isNotEmpty) {
      throw ValidationException('使用中の色ラベルは削除できません');
    }
    await db.deleteRows('calendar_labels', 'id', labelId);
  });
}
