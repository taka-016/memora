import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/repositories/calendar/sqlite_calendar_event_repository.dart';
import 'package:memora/infrastructure/queries/calendar/sqlite_calendar_event_query_service.dart';

void main() {
  test('固定ラベルをDBに作らず予定と個別回の参照を保存し所属解除後も保持する', () async {
    final db = OfflineDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.insertRow('groups', {'id': 'g', 'owner_id': 'm', 'name': '家族', 'color': '#123456'});
    await db.insertRow('members', {'id': 'm', 'display_name': '太郎'});
    await db.insertRow('group_members', {'group_id': 'g', 'member_id': 'm', 'is_administrator': 1, 'order_index': 0, 'color': '#ABCDEF'});
    final repository = SqliteCalendarEventRepository(db);
    await repository.saveCalendarEvent(CalendarEvent(id: '', groupId: 'g', labelType: 'group', title: '家族', startDateTime: DateTime.utc(2026, 10, 1), endDateTime: DateTime.utc(2026, 10, 1), isAllDay: true, recurrenceRule: 'FREQ=DAILY;COUNT=3', overrides: [
      CalendarEventOverride(originalStartDateTime: DateTime.utc(2026, 10, 2), isCancelled: false, title: '太郎', startDateTime: DateTime.utc(2026, 10, 2), endDateTime: DateTime.utc(2026, 10, 2), isAllDay: true, labelType: 'member', memberId: 'm'),
    ]));
    await db.deleteRows('group_members', 'member_id', 'm');
    final saved = (await SqliteCalendarEventQueryService(db).getCalendarEventsByGroupId('g')).single;
    expect(saved.labelType, 'group');
    expect(saved.overrides.single.memberId, 'm');
    expect(saved.overrides.single.labelType, 'member');
    expect(await db.rows('calendar_labels'), isEmpty);
    expect((await db.rows('groups')).single['color'], '#123456');
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}
