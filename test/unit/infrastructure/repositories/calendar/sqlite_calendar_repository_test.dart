import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/application/usecases/calendar/change_calendar_recurrence_usecase.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
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

  test('取消は表示期間と重なる回だけ取得し保存時は未取得の過去と未来の取消を保持する', () async {
    final labelId = await labels.saveCalendarLabel(label());
    final keys = [DateTime.utc(2021, 1, 2), DateTime.utc(2026, 11, 8), DateTime.utc(2026, 11, 11), DateTime.utc(2027, 1, 1)];
    final id = await events.saveCalendarEvent(CalendarEvent(id: '', groupId: 'family', labelId: labelId, title: '系列',
      startDateTime: DateTime.utc(2021), endDateTime: DateTime.utc(2021, 1, 4), isAllDay: true, recurrenceRule: 'FREQ=DAILY',
      overrides: [for (final key in keys) CalendarEventOverride(originalStartDateTime: key, isCancelled: true)]));
    final period = CalendarEventPeriod(from: DateTime.utc(2026, 11, 10), to: DateTime.utc(2026, 11, 13));
    final loaded = (await eventQuery.getCalendarEventsByGroupId('family', period: period)).single;
    expect(loaded.overrides.map((value) => value.originalStartDateTime), keys.sublist(1, 3));
    final selected = DateTime.utc(2026, 11, 12);
    await container.read(changeCalendarRecurrenceUsecaseProvider).execute(loaded, selected, CalendarChangeScope.only,
      changes: loaded.copyWith(title: '独立した予定', startDateTime: selected, endDateTime: selected.add(const Duration(days: 3))));
    final saved = await eventQuery.getCalendarEventsByGroupId('family');
    final parent = saved.singleWhere((value) => value.id == id);
    expect(parent.overrides.map((value) => value.originalStartDateTime), unorderedEquals([...keys, selected]));
    final independent = saved.singleWhere((value) => value.id != id);
    expect(independent.recurrenceRule, isNull);
    expect(independent.originalStartDateTime, isNull);
    await events.deleteCalendarEvent(id);
    expect((await eventQuery.getCalendarEventsByGroupId('family')).single.id, independent.id);
  });

  test('期間取得は過去・遠い未来の通常予定と終了済み系列を除き跨ぐ予定を取得する', () async {
    final labelId = await labels.saveCalendarLabel(label());
    final normal = event(labelId);
    final definitions = {
      '過去': normal.copyWith(
        startDateTime: DateTime(2021, 1, 1),
        endDateTime: DateTime(2021, 1, 2),
      ),
      '未来': normal.copyWith(
        startDateTime: DateTime(2028, 1, 1),
        endDateTime: DateTime(2028, 1, 2),
      ),
      '期間内': normal.copyWith(
        startDateTime: DateTime(2026, 11, 11),
        endDateTime: DateTime(2026, 11, 12),
      ),
      '跨ぐ予定': normal.copyWith(
        startDateTime: DateTime(2026, 10, 1),
        endDateTime: DateTime(2026, 12, 1),
      ),
      '境界の瞬間': normal.copyWith(
        startDateTime: DateTime(2026, 11, 10),
        endDateTime: DateTime(2026, 11, 10),
      ),
      '過去の系列': normal.copyWith(
        startDateTime: DateTime(2021, 1, 1, 12),
        endDateTime: DateTime(2021, 1, 1, 13),
        recurrenceRule: 'FREQ=DAILY;COUNT=2',
        timeZone: 'Asia/Tokyo',
        overrides: [
          CalendarEventOverride(originalStartDateTime: DateTime(2021, 1, 1, 12).toUtc(), isCancelled: true),
        ],
      ),
    };
    for (final entry in definitions.entries) {
      await events.saveCalendarEvent(entry.value.copyWith(title: entry.key));
    }
    final loaded = await eventQuery.getCalendarEventsByGroupId(
      'family',
      period: CalendarEventPeriod(
        from: DateTime(2026, 11, 10),
        to: DateTime(2026, 12, 1),
      ),
    );
    expect(
      loaded.map((value) => value.title),
      unorderedEquals(['期間内', '跨ぐ予定', '境界の瞬間']),
    );
  });

  test('系列を単発へ変更するとき個別予定を同じトランザクションで維持する', () async {
    final labelId = await labels.saveCalendarLabel(label());
    final foreign = await labels.saveCalendarLabel(label(group: 'friends'));
    final id = await events.saveCalendarEvent(
      event(
        labelId,
        allDay: true,
      ).copyWith(recurrenceRule: 'FREQ=DAILY;COUNT=3'),
    );
    final source = (await eventQuery.getCalendarEventsByGroupId('family'))
        .single;
    final expected = CalendarEventMapper.toEntity(source);
    final replacement = event(labelId, id: id, allDay: true);
    final individual = event(labelId).copyWith(title: '個別予定');
    await expectLater(
      events.replaceCalendarEvent(
        expected,
        replacement,
        null,
        preservedEvents: [individual.copyWith(labelId: foreign)],
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(
      (await eventQuery.getCalendarEventsByGroupId('family')).single,
      source,
    );
    await events.replaceCalendarEvent(
      expected,
      replacement,
      null,
      preservedEvents: [individual],
    );
    final saved = await eventQuery.getCalendarEventsByGroupId('family');
    expect(saved, hasLength(2));
    expect(
      saved.singleWhere((value) => value.title == '個別予定').recurrenceRule,
      isNull,
    );
    expect(saved.singleWhere((value) => value.id == id).recurrenceRule, isNull);
  });
  test('分割は原子的に保存し別ラベルの失敗と競合時には元の系列を維持する', () async {
    final labelId = await labels.saveCalendarLabel(label());
    final foreign = await labels.saveCalendarLabel(label(group: 'friends'));
    final id = await events.saveCalendarEvent(
      event(
        labelId,
        allDay: true,
      ).copyWith(recurrenceRule: 'FREQ=DAILY;COUNT=5'),
    );
    final source = (await eventQuery.getCalendarEventsByGroupId('family'))
        .single;
    final expected = CalendarEventMapper.toEntity(source);
    final before = expected.copyWith(recurrenceRule: 'FREQ=DAILY;COUNT=2');
    final after = expected.copyWith(
      id: '',
      startDateTime: DateTime.utc(2026, 10, 3),
      endDateTime: DateTime.utc(2026, 10, 5),
      recurrenceRule: 'FREQ=DAILY;COUNT=3',
    );
    await expectLater(
      events.replaceCalendarEvent(
        expected,
        before,
        after.copyWith(labelId: foreign),
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(
      (await eventQuery.getCalendarEventsByGroupId('family')).single,
      source,
    );
    await events.replaceCalendarEvent(expected, before, after);
    final saved = await eventQuery.getCalendarEventsByGroupId('family');
    expect(saved, hasLength(2));
    expect(
      saved.singleWhere((v) => v.id == id).recurrenceRule,
      'FREQ=DAILY;COUNT=2',
    );
    await expectLater(
      events.replaceCalendarEvent(expected, before, after),
      throwsA(isA<ValidationException>()),
    );
    expect(await eventQuery.getCalendarEventsByGroupId('family'), saved);
  });

  test('取消を持つ系列と独立した通常予定を保存し不正ラベル時は予定を維持する', () async {
    final base = await labels.saveCalendarLabel(label());
    final changed = await labels.saveCalendarLabel(label(name: '太郎'));
    final foreign = await labels.saveCalendarLabel(label(group: 'friends'));
    final id = await events.saveCalendarEvent(event(base, allDay: true).copyWith(
      recurrenceRule: 'FREQ=DAILY;COUNT=3', overrides: [CalendarEventOverride(originalStartDateTime: DateTime.utc(2026, 10, 2), isCancelled: true)]));
    final detachedId = await events.saveCalendarEvent(event(changed, allDay: true).copyWith(title: '移動'));
    final detached = (await eventQuery.getCalendarEventsByGroupId('family')).singleWhere((value) => value.id == detachedId);
    expect(detached.overrides, isEmpty);
    expect(detached.recurrenceRule, isNull);
    await expectLater(events.updateCalendarEvent(CalendarEventMapper.toEntity(detached).copyWith(labelId: foreign)), throwsA(isA<ValidationException>()));
    expect((await eventQuery.getCalendarEventsByGroupId('family')).singleWhere((value) => value.id == detachedId).labelId, changed);
    await expectLater(labels.deleteCalendarLabel(changed), throwsA(isA<ValidationException>()));
    await events.deleteCalendarEvent(id);
    expect(await db.rows('calendar_event_overrides'), isEmpty);
    expect((await eventQuery.getCalendarEventsByGroupId('family')).single.id, detachedId);
    await events.deleteCalendarEvent(detachedId);
    await labels.deleteCalendarLabel(changed);
  });

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
  test('ドラッグ順を一括保存し名前と色を保ち不正な参照では全件を戻す', () async {
    final a = await labels.saveCalendarLabel(
      label(name: '先').copyWith(sortOrder: 7),
    );
    final b = await labels.saveCalendarLabel(
      label(name: '後').copyWith(sortOrder: 8),
    );
    final foreign = await labels.saveCalendarLabel(label(group: 'friends'));
    await expectLater(
      labels.reorderCalendarLabels('family', [a, foreign]),
      throwsA(isA<ValidationException>()),
    );
    expect(
      (await labelQuery.getCalendarLabelsByGroupId('family'))
          .map((label) => label.sortOrder),
      [7, 8],
    );
    await labels.reorderCalendarLabels('family', [b, a]);
    final sorted = await labelQuery.getCalendarLabelsByGroupId('family');
    expect(sorted.map((label) => label.id), [b, a]);
    expect(sorted.map((label) => label.sortOrder), [0, 1]);
    expect(sorted.map((label) => label.name), ['後', '先']);
    expect(sorted.every((label) => label.color == '#123ABC'), isTrue);
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
