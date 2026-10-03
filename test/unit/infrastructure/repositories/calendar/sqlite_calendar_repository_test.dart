import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/application/queries/calendar/calendar_label_query_service.dart';
import 'package:memora/composition_root/providers/offline_database_provider.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/entities/calendar/calendar_label.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';
import 'package:memora/domain/repositories/calendar/calendar_label_repository.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

void main() {
  late OfflineDatabase db;
  late ProviderContainer container;
  late CalendarEventRepository events;
  late CalendarLabelRepository labels;
  late CalendarEventQueryService eventQuery;
  late CalendarLabelQueryService labelQuery;
  setUp(() async {
    db = OfflineDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.offline),
        offlineDatabaseProvider.overrideWithValue(db),
      ],
    );
    events = container.read(
      Provider(
        (ref) => RepositoryFactory.create<CalendarEventRepository>(ref: ref),
      ),
    );
    labels = container.read(
      Provider(
        (ref) => RepositoryFactory.create<CalendarLabelRepository>(ref: ref),
      ),
    );
    eventQuery = container.read(
      Provider(
        (ref) =>
            QueryServiceFactory.create<CalendarEventQueryService>(ref: ref),
      ),
    );
    labelQuery = container.read(
      Provider(
        (ref) =>
            QueryServiceFactory.create<CalendarLabelQueryService>(ref: ref),
      ),
    );
    await db.insertRow('members', {'id': 'self', 'display_name': '本人'});
    for (final id in ['family', 'friends']) {
      await db.insertRow('groups', {'id': id, 'owner_id': 'self', 'name': id});
    }
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  CalendarLabel label({
    String id = '',
    String group = 'family',
    String name = '家族全員',
  }) => CalendarLabel(id: id, groupId: group, name: name, color: '#123ABC');
  CalendarEvent event(String labelId, {String id = '', bool allDay = false}) =>
      CalendarEvent(
        id: id,
        groupId: 'family',
        labelId: labelId,
        title: '旅行',
        startDateTime: DateTime(2026, 10, 1, allDay ? 0 : 12, 0, 0, 123, 456),
        endDateTime: DateTime(2026, 10, 3),
        isAllDay: allDay,
      );

  test('SQLiteで白黒以外の文字色も登録・変更・取得する', () async {
    final id = await labels.saveCalendarLabel(
      label().copyWith(textColor: '#Ab12Cd'),
    );
    expect(
      (await labelQuery.getCalendarLabelsByGroupId('family')).single.textColor,
      '#Ab12Cd',
    );
    await labels.saveCalendarLabel(
      label(id: id).copyWith(textColor: '#000000'),
    );
    expect(
      (await labelQuery.getCalendarLabelsByGroupId('family')).single.textColor,
      '#000000',
    );
  });
  test('並び順を保存してラベルを指定順に取得する', () async {
    await labels.saveCalendarLabel(label(name: '後').copyWith(sortOrder: 5));
    await labels.saveCalendarLabel(label(name: '先').copyWith(sortOrder: 1));
    expect(
      (await labelQuery.getCalendarLabelsByGroupId('family'))
          .map((label) => label.name),
      ['先', '後'],
    );
  });
  test('モード別依存から予定とラベルの登録・取得・変更・削除を完結する', () async {
    final labelId = await labels.saveCalendarLabel(label());
    final otherId = await labels.saveCalendarLabel(label(name: '太郎'));
    final value = event(labelId);
    final id = await events.saveCalendarEvent(value);
    final saved = (await eventQuery.getCalendarEventsByGroupId('family'))
        .single;
    expect(saved.startDateTime, value.startDateTime);
    expect(saved.title, '旅行');
    expect(await eventQuery.getCalendarEventsByGroupId('friends'), isEmpty);
    await labels.saveCalendarLabel(label(id: labelId, name: '全員'));
    expect(
      (await labelQuery.getCalendarLabelsByGroupId('family'))
          .map((v) => v.name),
      contains('全員'),
    );
    await expectLater(
      labels.deleteCalendarLabel(labelId),
      throwsA(isA<ValidationException>()),
    );
    await events.updateCalendarEvent(
      value.copyWith(id: id, title: '変更', labelId: otherId),
    );
    await labels.deleteCalendarLabel(labelId);
    expect(
      (await eventQuery.getCalendarEventsByGroupId('family')).single.labelId,
      otherId,
    );
    await events.deleteCalendarEvent(id);
    await labels.deleteCalendarLabel(otherId);
    expect(await eventQuery.getCalendarEventsByGroupId('family'), isEmpty);
    expect(await labelQuery.getCalendarLabelsByGroupId('family'), isEmpty);
  });

  test('別グループや存在しないラベルへの登録・更新を拒否して元の予定を維持する', () async {
    final labelId = await labels.saveCalendarLabel(label());
    final otherId = await labels.saveCalendarLabel(label(group: 'friends'));
    final id = await events.saveCalendarEvent(event(labelId));
    for (final invalid in [otherId, 'missing']) {
      await expectLater(
        events.saveCalendarEvent(event(invalid)),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        events.updateCalendarEvent(event(invalid, id: id)),
        throwsA(isA<ValidationException>()),
      );
    }
    expect(
      (await eventQuery.getCalendarEventsByGroupId('family')).single.labelId,
      labelId,
    );
    await expectLater(
      labels.saveCalendarLabel(label(id: labelId, group: 'friends')),
      throwsA(isA<ValidationException>()),
    );
  });

  test('終日予定は時刻や端末のタイムゾーンに依存しない日付として往復する', () async {
    final labelId = await labels.saveCalendarLabel(label());
    await events.saveCalendarEvent(event(labelId, allDay: true));
    final saved = (await eventQuery.getCalendarEventsByGroupId('family'))
        .single;
    expect(saved.startDateTime, DateTime.utc(2026, 10, 1));
    expect(saved.endDateTime, DateTime.utc(2026, 10, 3));
    expect(saved.isAllDay, isTrue);
  });
}
