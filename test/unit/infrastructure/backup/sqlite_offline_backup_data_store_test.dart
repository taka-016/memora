import 'package:memora/infrastructure/repositories/member/sqlite_member_repository.dart';
import 'package:memora/infrastructure/repositories/group/sqlite_group_repository.dart';
import 'package:memora/infrastructure/queries/member/sqlite_member_query_service.dart';
import 'package:memora/infrastructure/queries/group/sqlite_group_query_service.dart';

import 'dart:convert';

import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/application/usecases/calendar/change_calendar_recurrence_usecase.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/infrastructure/queries/calendar/sqlite_calendar_event_query_service.dart';
import 'package:memora/infrastructure/repositories/calendar/sqlite_calendar_event_repository.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/application/services/offline_backup_current_member_storage.dart';
import 'package:memora/application/services/offline_backup_restore_journal_storage.dart';
import 'package:memora/application/services/offline_backup_restore_sync_storage.dart';
import 'package:memora/application/services/offline_backup_settings_storage.dart';
import 'package:memora/infrastructure/backup/sqlite_offline_backup_data_store.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

import '../../../helpers/test_exception.dart';

void main() {
  late OfflineDatabase db;
  late _FakeCurrentMemberStorage memberStorage;
  late _FakeSettingsStorage settingsStorage;
  late _FakeRestoreJournalStorage journalStorage;
  late _FakeRestoreSyncStorage syncStorage;
  late SqliteOfflineBackupDataStore dataStore;

  const originalMember = OfflineBackupCurrentMember(
    id: 'member-1',
    accountId: 'account-1',
    displayName: '本人',
  );
  const originalSettings = OfflineBackupSettings(
    androidWidgetUpdateIntervalMinutes: 360,
    showAge: true,
    showGrade: false,
    showYakudoshi: true,
  );

  setUp(() async {
    db = OfflineDatabase(NativeDatabase.memory());
    memberStorage = _FakeCurrentMemberStorage(originalMember);
    settingsStorage = _FakeSettingsStorage(originalSettings);
    journalStorage = _FakeRestoreJournalStorage();
    syncStorage = _FakeRestoreSyncStorage();
    dataStore = SqliteOfflineBackupDataStore(
      database: db,
      currentMemberStorage: memberStorage,
      settingsStorage: settingsStorage,
      restoreJournalStorage: journalStorage,
      restoreSyncStorage: syncStorage,
    );
    await db.insertRow('members', {
      'id': originalMember.id,
      'account_id': originalMember.accountId,
      'display_name': originalMember.displayName,
    });
    await db.insertRow('groups', {
      'id': 'group-1',
      'owner_id': originalMember.id,
      'name': '家族',
    });
  });

  tearDown(() => db.close());

  Future<void> archiveParentsWithRelatedData() async {
    final rows = <String, List<Map<String, Object?>>>{
      'members': [
        {'id': 'member', 'owner_id': originalMember.id, 'display_name': '家族'},
      ],
      'group_members': [
        {
          'group_id': 'group-1',
          'member_id': 'member',
          'is_administrator': 1,
          'order_index': 3,
        },
      ],
      'trip_entries': [
        {'id': 'trip', 'group_id': 'group-1', 'year': 2026},
      ],
      'tasks': [
        {
          'id': 'task',
          'trip_id': 'trip',
          'name': '準備',
          'order_index': 0,
          'is_completed': 0,
          'assigned_member_id': 'member',
        },
      ],
      'itinerary_items': [
        {'id': 'item', 'trip_id': 'trip', 'name': '出発'},
      ],
      'member_events': [
        {'id': 'me', 'member_id': 'member', 'year': 2026, 'memo': '入学'},
      ],
      'group_events': [
        {'id': 'ge', 'group_id': 'group-1', 'year': 2026, 'memo': '記念'},
      ],
      'calendar_labels': [
        {
          'id': 'label',
          'group_id': 'group-1',
          'name': '全員',
          'color': '#123456',
        },
      ],
      'calendar_events': [
        {
          'id': 'event',
          'group_id': 'group-1',
          'label_id': 'label',
          'label_type': 'custom',
          'title': '予定',
          'start_date_time': 1,
          'end_date_time': 2,
          'is_all_day': 1,
          'recurrence_rule': 'FREQ=DAILY',
        },
      ],
      'calendar_event_overrides': [
        {
          'event_id': 'event',
          'group_id': 'group-1',
          'original_start_date_time': 1,
          'is_cancelled': 1,
        },
      ],
      'dvc_point_contracts': [
        {
          'id': 'contract',
          'group_id': 'group-1',
          'contract_name': '契約',
          'contract_start_year_month': 1,
          'contract_end_year_month': 2,
          'use_year_start_month': 1,
          'annual_point': 100,
        },
      ],
      'dvc_limited_points': [
        {
          'id': 'limited',
          'group_id': 'group-1',
          'contract_id': 'contract',
          'start_year_month': 1,
          'end_year_month': 2,
          'point': 10,
        },
      ],
      'dvc_point_usages': [
        {
          'id': 'usage',
          'group_id': 'group-1',
          'contract_id': 'contract',
          'usage_year_month': 1,
          'used_point': 5,
        },
      ],
    };
    for (final table in rows.entries) {
      for (final row in table.value) {
        await db.insertRow(table.key, row);
      }
    }
    await SqliteGroupRepository(db).deleteGroup('group-1');
    await SqliteMemberRepository(db).deleteMember('member');
  }

  Future<void> expectDatabaseMatches(OfflineBackupSnapshot snapshot) async {
    for (final table in db.allTables) {
      expect(
        await db.rows(table.actualTableName),
        snapshot.tables[table.actualTableName],
        reason: table.actualTableName,
      );
    }
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  }

  test('退避した親と全関連データを同じスナップショットから復元し通常取得から除外する', () async {
    await archiveParentsWithRelatedData();
    final snapshot = OfflineBackupSnapshot.fromJson(
      jsonDecode(jsonEncode((await dataStore.exportSnapshot()).toJson()))
          as Map<String, dynamic>,
    );
    expect(snapshot.tables['deleted_groups']!.single['id'], 'group-1');
    expect(snapshot.tables['deleted_members']!.single['id'], 'member');
    await db.updateRow('deleted_groups', 'group-1', {'name': '別時点'});
    await db.updateRow('deleted_members', 'member', {'display_name': '別時点'});
    await db.insertRow('deleted_groups', {
      'id': 'other',
      'owner_id': originalMember.id,
      'name': '別の退避',
    });
    await db.insertRow('deleted_members', {
      'id': 'other',
      'display_name': '別の退避',
    });
    await db.updateRow('tasks', 'task', {'name': '別時点'});

    await dataStore.restoreSnapshot(snapshot);

    await expectDatabaseMatches(snapshot);
    expect(
      await SqliteGroupQueryService(db)
          .getGroupsWithMembersByMemberId(originalMember.id),
      isEmpty,
    );
    expect(
      await SqliteGroupQueryService(db).getGroupWithMembersById('group-1'),
      isNull,
    );
    expect(await SqliteMemberQueryService(db).getMemberById('member'), isNull);
    expect((await SqliteMemberQueryService(db).getMembers()).map((v) => v.id), [
      originalMember.id,
    ]);
  });

  test('空の退避テーブルを復元すると端末に残っていた退避内容も置換する', () async {
    final snapshot = await dataStore.exportSnapshot();
    expect(snapshot.tables['deleted_groups'], isEmpty);
    expect(snapshot.tables['deleted_members'], isEmpty);
    await archiveParentsWithRelatedData();

    await dataStore.restoreSnapshot(snapshot);

    await expectDatabaseMatches(snapshot);
  });

  for (final failure in ['設定保存', 'ジャーナル削除', '同期保留']) {
    test('$failureの失敗で通常データと退避データと関連データを復元前へ戻す', () async {
      final target = await dataStore.exportSnapshot();
      await archiveParentsWithRelatedData();
      final before = await dataStore.exportSnapshot();
      final error = TestException('復元失敗');
      switch (failure) {
        case '設定保存':
          settingsStorage.nextSaveError = error;
        case 'ジャーナル削除':
          journalStorage.nextClearError = error;
        case '同期保留':
          syncStorage.nextMarkError = error;
      }

      await expectLater(
        dataStore.restoreSnapshot(target),
        throwsA(same(error)),
      );

      await expectDatabaseMatches(before);
      expect(journalStorage.value, isNull);
      expect(await syncStorage.isPending(), isFalse);
    });
  }

  test('中断後のジャーナルから通常データと退避データと関連データを同時に回復する', () async {
    await archiveParentsWithRelatedData();
    final before = await dataStore.exportSnapshot();
    await journalStorage.save(before);
    await db.deleteRows('deleted_groups', 'id', 'group-1');
    await db.updateRow('deleted_members', 'member', {'display_name': '復元途中'});
    await db.insertRow('groups', {
      'id': 'group-1',
      'owner_id': originalMember.id,
      'name': '復元途中',
    });
    await db.updateRow('tasks', 'task', {'name': '復元途中'});

    await dataStore.recoverPendingRestore();

    await expectDatabaseMatches(before);
    expect(journalStorage.value, isNull);
  });

  test('更新前のバックアップ形式は読み込み時に拒否する', () async {
    final json = (await dataStore.exportSnapshot()).toJson();
    json['formatVersion'] = 1;
    expect(
      () => OfflineBackupSnapshot.fromJson(json),
      throwsA(isA<OfflineBackupUnsupportedVersionException>()),
    );
  });

  test('退避テーブルが欠けたバックアップは書き込み前に拒否する', () async {
    final snapshot = await dataStore.exportSnapshot();
    for (final table in ['deleted_groups', 'deleted_members']) {
      final tables = {...snapshot.tables}..remove(table);
      await expectLater(
        dataStore.restoreSnapshot(
          OfflineBackupSnapshot(
            formatVersion: snapshot.formatVersion,
            databaseSchemaVersion: snapshot.databaseSchemaVersion,
            currentMember: snapshot.currentMember,
            settings: snapshot.settings,
            tables: tables,
          ),
        ),
        throwsFormatException,
      );
    }
    await expectDatabaseMatches(snapshot);
  });

  test('全業務テーブルと端末内本人と復元対象設定を論理データとして往復復元する', () async {
    final snapshot = await dataStore.exportSnapshot();

    expect(snapshot.formatVersion, OfflineBackupSnapshot.currentFormatVersion);
    expect(snapshot.databaseSchemaVersion, db.schemaVersion);
    expect(snapshot.currentMember, originalMember);
    expect(snapshot.settings, originalSettings);
    expect(snapshot.tables.keys, OfflineBackupSnapshot.tableNames);
    expect(snapshot.tables['groups']!.single['name'], '家族');

    await db.updateRow('groups', 'group-1', {'name': '変更後'});
    memberStorage.value = const OfflineBackupCurrentMember(
      id: 'other',
      accountId: 'other-account',
      displayName: '別人',
    );
    settingsStorage.value = const OfflineBackupSettings(
      androidWidgetUpdateIntervalMinutes: 1440,
      showAge: false,
      showGrade: false,
      showYakudoshi: false,
    );

    await dataStore.restoreSnapshot(snapshot);

    expect((await db.rows('groups')).single['name'], '家族');
    expect(memberStorage.value, originalMember);
    expect(settingsStorage.value, originalSettings);
    expect(await syncStorage.isPending(), isTrue);
  });

  test('DVCの契約と利用・期間限定ポイントの紐付けを往復復元し不正な参照は拒否する', () async {
    await db.insertRow('dvc_point_contracts', {
      'id': 'c1',
      'group_id': 'group-1',
      'contract_name': '契約A',
      'contract_start_year_month': 0,
      'contract_end_year_month': 0,
      'use_year_start_month': 1,
      'annual_point': 100,
    });
    await db.insertRow('dvc_point_usages', {
      'id': 'u1',
      'group_id': 'group-1',
      'contract_id': 'c1',
      'usage_year_month': 0,
      'used_point': 60,
    });
    await db.insertRow('dvc_limited_points', {
      'id': 'l1',
      'group_id': 'group-1',
      'contract_id': 'c1',
      'start_year_month': 0,
      'end_year_month': 0,
      'point': 30,
    });
    final snapshot = await dataStore.exportSnapshot();
    await dataStore.restoreSnapshot(snapshot);
    expect((await db.rows('dvc_point_usages')).single['contract_id'], 'c1');
    expect((await db.rows('dvc_limited_points')).single['contract_id'], 'c1');
    for (final table in ['dvc_point_usages', 'dvc_limited_points']) {
      final tables = {
        ...snapshot.tables,
        table: [
          {...snapshot.tables[table]!.single, 'contract_id': 'unknown'},
        ],
      };
      expect(
        () => dataStore.validateSnapshot(
          OfflineBackupSnapshot(
            formatVersion: snapshot.formatVersion,
            databaseSchemaVersion: snapshot.databaseSchemaVersion,
            currentMember: snapshot.currentMember,
            settings: snapshot.settings,
            tables: tables,
          ),
        ),
        throwsFormatException,
      );
      expect((await db.rows(table)).single['contract_id'], 'c1');
    }
  });

  test('グループ色・所属色・固定ラベル参照をバックアップして復元する', () async {
    await db.updateRow('groups', 'group-1', {
      'color': '#123456',
      'text_color': '#FFFFFF',
    });
    await db.insertRow('group_members', {
      'group_id': 'group-1',
      'member_id': originalMember.id,
      'is_administrator': 1,
      'order_index': 0,
      'color': '#ABCDEF',
      'text_color': '#000000',
    });
    final repository = SqliteCalendarEventRepository(db);
    final query = SqliteCalendarEventQueryService(db);
    final usecase = ChangeCalendarRecurrenceUsecase(
      repository,
      CalendarRecurrenceExpander(IanaCalendarTimeZone()),
    );
    final groupEvent = CalendarEventDto(
      id: '',
      groupId: 'group-1',
      labelType: 'group',
      title: '家族旅行',
      startDateTime: DateTime.utc(2026, 10, 1),
      endDateTime: DateTime.utc(2026, 10, 1),
      isAllDay: true,
      recurrenceRule: 'FREQ=DAILY;COUNT=4',
    );
    await repository.saveCalendarEvent(
      CalendarEventMapper.toEntity(groupEvent),
    );
    final source = (await query.getCalendarEventsByGroupId('group-1')).single;
    await usecase.execute(
      source,
      DateTime.utc(2026, 10, 2),
      CalendarChangeScope.only,
      changes: source.copyWith(
        labelType: 'member',
        memberId: originalMember.id,
      ),
    );
    final before = await query.getCalendarEventsByGroupId('group-1');
    final backup = await dataStore.exportSnapshot();
    await db.updateRow('groups', 'group-1', {'color': '#FFFFFF'});
    await repository.deleteCalendarEvent(before.single.id);
    await dataStore.restoreSnapshot(backup);
    expect(await query.getCalendarEventsByGroupId('group-1'), before);
    expect((await db.rows('groups')).single['text_color'], '#FFFFFF');
    expect((await db.rows('group_members')).single['text_color'], '#000000');
    expect((await db.rows('groups')).single['color'], '#123456');
    expect((await db.rows('group_members')).single['color'], '#ABCDEF');
    expect(
      (await query.getCalendarEventsByGroupId('group-1'))
          .single
          .overrides
          .single
          .memberId,
      originalMember.id,
    );
    expect(await db.rows('calendar_labels'), isEmpty);
  });

  test('個別回の移動・取消しと分割した系列を復元して同じ予定を再現する', () async {
    await db.insertRow('calendar_labels', {
      'id': 'label',
      'group_id': 'group-1',
      'name': '全員',
      'color': '#123ABC',
    });
    final repository = SqliteCalendarEventRepository(db);
    final query = SqliteCalendarEventQueryService(db);
    final expander = CalendarRecurrenceExpander(IanaCalendarTimeZone());
    final usecase = ChangeCalendarRecurrenceUsecase(repository, expander);
    final value = CalendarEventDto(
      id: '',
      groupId: 'group-1',
      labelId: 'label',
      title: '予定',
      startDateTime: DateTime.utc(2026, 10, 1),
      endDateTime: DateTime.utc(2026, 10, 3),
      isAllDay: true,
      recurrenceRule: 'FREQ=DAILY;COUNT=6',
      notificationMinutesBefore: [1440],
      overrides: [
        CalendarEventOverride(
          originalStartDateTime: DateTime.utc(2026, 10, 2),
          isCancelled: true,
        ),
      ],
    );
    await repository.saveCalendarEvent(CalendarEventMapper.toEntity(value));
    var source = (await query.getCalendarEventsByGroupId('group-1')).single;
    await usecase.execute(
      source,
      source.startDateTime,
      CalendarChangeScope.only,
      changes: source.copyWith(
        title: '移動',
        notificationMinutesBefore: [],
        startDateTime: DateTime.utc(2026, 11, 1),
        endDateTime: DateTime.utc(2026, 11, 2),
      ),
    );
    source = (await query.getCalendarEventsByGroupId('group-1')).single;
    await usecase.execute(
      source,
      DateTime.utc(2026, 10, 3),
      CalendarChangeScope.following,
      changes: source.copyWith(
        startDateTime: DateTime.utc(2026, 10, 3),
        endDateTime: DateTime.utc(2026, 10, 5),
      ),
    );
    Future<List<CalendarEventDto>> expanded() async =>
        (await query.getCalendarEventsByGroupId('group-1'))
            .expand(
              (v) => expander.expand(
                v,
                DateTime.utc(2026, 10),
                DateTime.utc(2026, 12),
              ),
            )
            .toList();
    final before = await expanded();
    expect(before, hasLength(5));
    expect(
      before.where((v) => v.title == '移動').single.notificationMinutesBefore,
      isEmpty,
    );
    expect(
      before
          .where((v) => v.title != '移動')
          .every((v) => v.notificationMinutesBefore.single == 1440),
      isTrue,
    );
    expect(before.where((v) => v.title == '移動'), hasLength(1));
    final snapshot = await dataStore.exportSnapshot();
    await db.deleteRows('groups', 'id', 'group-1');
    await dataStore.restoreSnapshot(snapshot);
    expect(await expanded(), before);
  });

  test('繰り返しルールと取消しを復元後も保持する', () async {
    await db.insertRow('calendar_labels', {
      'id': 'label',
      'group_id': 'group-1',
      'name': '全員',
      'color': '#123ABC',
    });
    await db.insertRow('calendar_events', {
      'id': 'series',
      'group_id': 'group-1',
      'label_id': 'label',
      'label_type': 'custom',
      'title': '予定',
      'start_date_time': 1,
      'end_date_time': 2,
      'is_all_day': 0,
      'recurrence_rule': 'FREQ=DAILY;COUNT=3',
      'time_zone': 'Asia/Tokyo',
    });
    await db.insertRow('calendar_event_overrides', {
      'event_id': 'series',
      'group_id': 'group-1',
      'original_start_date_time': 86400000001,
      'is_cancelled': 1,
    });
    final snapshot = await dataStore.exportSnapshot();
    await db.deleteRows('groups', 'id', 'group-1');
    await dataStore.restoreSnapshot(snapshot);
    expect(
      (await db.rows('calendar_events')).single['recurrence_rule'],
      'FREQ=DAILY;COUNT=3',
    );
    expect(
      (await db.rows('calendar_event_overrides')).single['is_cancelled'],
      1,
    );
  });

  test('不正な繰り返しルールと親のない上書きは復元確認前に拒否する', () async {
    final original = await dataStore.exportSnapshot();
    final tables = {...original.tables};
    tables['calendar_events'] = [
      {
        'id': 'invalid',
        'notification_minutes_before': '[]',
        'group_id': 'group-1',
        'label_id': 'label',
        'label_type': 'custom',
        'title': '予定',
        'start_date_time': 1,
        'end_date_time': 2,
        'is_all_day': 1,
        'recurrence_rule': 'FREQ=DAILY;COUNT=0',
        'time_zone': null,
      },
    ];
    final invalid = OfflineBackupSnapshot(
      formatVersion: original.formatVersion,
      databaseSchemaVersion: db.schemaVersion,
      currentMember: original.currentMember,
      settings: original.settings,
      tables: tables,
    );
    expect(
      () => dataStore.validateSnapshot(invalid),
      throwsA(isA<Exception>()),
    );
    tables['calendar_events'] = [];
    tables['calendar_event_overrides'] = [
      {
        'event_id': 'missing',
        'group_id': 'group-1',
        'original_start_date_time': 1,
        'is_cancelled': 1,
      },
    ];
    expect(
      () => dataStore.validateSnapshot(invalid),
      throwsA(isA<Exception>()),
    );
    expect((await db.rows('groups')).single['name'], '家族');
  });

  test('予定と色ラベルをバックアップして参照を保ったまま復元する', () async {
    await db.insertRow('calendar_labels', {
      'id': 'label',
      'group_id': 'group-1',
      'name': '家族全員',
      'color': '#123ABC',
      'text_color': '#Ab12Cd',
    });
    await db.insertRow('calendar_events', {
      'id': 'event',
      'group_id': 'group-1',
      'label_id': 'label',
      'label_type': 'custom',
      'title': '旅行',
      'start_date_time': 1,
      'end_date_time': 2,
      'is_all_day': 1,
    });
    final snapshot = await dataStore.exportSnapshot();
    expect(snapshot.tables['calendar_events']!.single['title'], '旅行');
    await db.deleteRows('groups', 'id', 'group-1');
    await dataStore.restoreSnapshot(snapshot);
    expect((await db.rows('calendar_events')).single['label_id'], 'label');
    expect((await db.rows('calendar_labels')).single['name'], '家族全員');
    expect((await db.rows('calendar_labels')).single['text_color'], '#Ab12Cd');
  });

  for (final version in [1, 2, 7, 8]) {
    test('旧バージョン$versionのバックアップは書き込み前に拒否する', () async {
      final snapshot = await dataStore.exportSnapshot();
      final tables = {...snapshot.tables};
      if (version == 1) {
        tables.remove('calendar_events');
        tables.remove('calendar_labels');
      } else {
        tables['calendar_labels'] = [
          {
            'id': 'label',
            'group_id': 'group-1',
            'name': '旧ラベル',
            'color': '#123ABC',
          },
        ];
      }
      final legacy = OfflineBackupSnapshot(
        formatVersion: snapshot.formatVersion,
        databaseSchemaVersion: version,
        currentMember: snapshot.currentMember,
        settings: snapshot.settings,
        tables: tables,
      );
      await db.updateRow('groups', 'group-1', {'name': '現在のデータ'});
      await expectLater(
        dataStore.restoreSnapshot(legacy),
        throwsA(isA<OfflineBackupUnsupportedVersionException>()),
      );
      expect((await db.rows('groups')).single['name'], '現在のデータ');
      expect(await db.rows('calendar_labels'), isEmpty);
      expect(await syncStorage.isPending(), isFalse);
    });
  }

  test('SQLite外の設定保存に失敗した場合はDBと端末内本人と設定をすべて維持する', () async {
    final snapshot = await dataStore.exportSnapshot();
    await db.updateRow('groups', 'group-1', {'name': '現在のデータ'});
    const currentMember = OfflineBackupCurrentMember(
      id: 'current-member',
      accountId: 'current-account',
      displayName: '現在の本人',
    );
    const currentSettings = OfflineBackupSettings(
      androidWidgetUpdateIntervalMinutes: 60,
      showAge: false,
      showGrade: true,
      showYakudoshi: false,
    );
    memberStorage.value = currentMember;
    settingsStorage.value = currentSettings;
    settingsStorage.nextSaveError = TestException('設定保存失敗');

    await expectLater(
      dataStore.restoreSnapshot(snapshot),
      throwsA(isA<TestException>()),
    );

    expect((await db.rows('groups')).single['name'], '現在のデータ');
    expect(memberStorage.value, currentMember);
    expect(settingsStorage.value, currentSettings);
  });

  test('未対応のDBスキーマと本人を含まないデータは書き込み前に拒否する', () async {
    final snapshot = await dataStore.exportSnapshot();

    await expectLater(
      dataStore.restoreSnapshot(
        snapshot.copyWith(databaseSchemaVersion: db.schemaVersion + 1),
      ),
      throwsA(isA<OfflineBackupUnsupportedVersionException>()),
    );
    await expectLater(
      dataStore.restoreSnapshot(
        snapshot.copyWith(
          currentMember: const OfflineBackupCurrentMember(
            id: 'missing',
            accountId: 'missing-account',
            displayName: '不在',
          ),
        ),
      ),
      throwsA(isA<FormatException>()),
    );

    expect((await db.rows('groups')).single['name'], '家族');
  });

  test('ジャーナル削除に失敗した場合は直ちに復元前の正本へ戻す', () async {
    final restoreTarget = await dataStore.exportSnapshot();
    await db.updateRow('members', originalMember.id, {'display_name': '現在の本人'});
    await db.updateRow('groups', 'group-1', {'name': '現在のデータ'});
    const currentMember = OfflineBackupCurrentMember(
      id: 'member-1',
      accountId: 'account-1',
      displayName: '現在の本人',
    );
    const currentSettings = OfflineBackupSettings(
      androidWidgetUpdateIntervalMinutes: 60,
      showAge: false,
      showGrade: true,
      showYakudoshi: false,
    );
    memberStorage.value = currentMember;
    settingsStorage.value = currentSettings;
    journalStorage.nextClearError = TestException('確定直後にプロセス終了');

    await expectLater(
      dataStore.restoreSnapshot(restoreTarget),
      throwsA(isA<TestException>()),
    );
    expect((await db.rows('groups')).single['name'], '現在のデータ');
    expect(memberStorage.value, currentMember);
    expect(settingsStorage.value, currentSettings);
    expect(journalStorage.value, isNull);
    expect(await syncStorage.isPending(), isFalse);

    await db.updateRow('groups', 'group-1', {'name': '失敗後の更新'});
    await dataStore.recoverPendingRestore();
    expect((await db.rows('groups')).single['name'], '失敗後の更新');
  });

  test('ジャーナルファイルの削除後に例外が出ても復元前の正本へ戻す', () async {
    final restoreTarget = await dataStore.exportSnapshot();
    await db.updateRow('groups', 'group-1', {'name': '現在のデータ'});
    journalStorage.nextClearErrorAfterDelete = TestException('一時ファイル削除失敗');

    await expectLater(
      dataStore.restoreSnapshot(restoreTarget),
      throwsA(isA<TestException>()),
    );

    expect((await db.rows('groups')).single['name'], '現在のデータ');
    expect(journalStorage.value, isNull);
    expect(await syncStorage.isPending(), isFalse);
  });

  test('プロセス終了後に残ったジャーナルから復元前の正本を回復する', () async {
    final previousSnapshot = await dataStore.exportSnapshot();
    await journalStorage.save(previousSnapshot);
    await db.updateRow('groups', 'group-1', {'name': '復元途中のデータ'});

    await dataStore.recoverPendingRestore();

    expect((await db.rows('groups')).single['name'], '家族');
    expect(journalStorage.value, isNull);
  });

  test('同期保留の記録に失敗した場合は直ちに復元前の正本へ戻す', () async {
    final restoreTarget = await dataStore.exportSnapshot();
    await db.updateRow('groups', 'group-1', {'name': '現在のデータ'});
    syncStorage.nextMarkError = TestException('同期保留の保存失敗');

    await expectLater(
      dataStore.restoreSnapshot(restoreTarget),
      throwsA(isA<TestException>()),
    );
    expect((await db.rows('groups')).single['name'], '現在のデータ');
    expect(memberStorage.value, originalMember);
    expect(settingsStorage.value, originalSettings);
    expect(journalStorage.value, isNull);
    expect(await syncStorage.isPending(), isFalse);

    await db.updateRow('groups', 'group-1', {'name': '失敗後の更新'});
    await dataStore.recoverPendingRestore();
    expect((await db.rows('groups')).single['name'], '失敗後の更新');
  });
}

class _FakeRestoreSyncStorage implements OfflineBackupRestoreSyncStorage {
  bool pending = false;
  TestException? nextMarkError;

  @override
  Future<void> markPending() async {
    final error = nextMarkError;
    nextMarkError = null;
    if (error != null) throw error;
    pending = true;
  }

  @override
  Future<bool> isPending() async => pending;

  @override
  Future<void> clear() async => pending = false;
}

class _FakeCurrentMemberStorage implements OfflineBackupCurrentMemberStorage {
  _FakeCurrentMemberStorage(this.value);

  OfflineBackupCurrentMember value;

  @override
  Future<OfflineBackupCurrentMember> load() async => value;

  @override
  Future<void> save(OfflineBackupCurrentMember member) async {
    value = member;
  }
}

class _FakeSettingsStorage implements OfflineBackupSettingsStorage {
  _FakeSettingsStorage(this.value);

  OfflineBackupSettings value;
  TestException? nextSaveError;

  @override
  Future<OfflineBackupSettings> load() async => value;

  @override
  Future<void> save(OfflineBackupSettings settings) async {
    final error = nextSaveError;
    nextSaveError = null;
    if (error != null) {
      throw error;
    }
    value = settings;
  }
}

class _FakeRestoreJournalStorage implements OfflineBackupRestoreJournalStorage {
  OfflineBackupSnapshot? value;
  TestException? nextClearError;
  TestException? nextClearErrorAfterDelete;

  @override
  Future<void> clear() async {
    final error = nextClearError;
    nextClearError = null;
    if (error != null) throw error;
    value = null;
    final afterDeleteError = nextClearErrorAfterDelete;
    nextClearErrorAfterDelete = null;
    if (afterDeleteError != null) throw afterDeleteError;
  }

  @override
  Future<OfflineBackupSnapshot?> load() async => value;

  @override
  Future<void> save(OfflineBackupSnapshot snapshot) async {
    value = snapshot;
  }
}
