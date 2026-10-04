import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/sqlite_calendar_event_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/calendar_override_mapper.dart';
import 'package:memora/infrastructure/services/validate_calendar_recurrence.dart';
import 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/application/services/offline_backup_current_member_storage.dart';
import 'package:memora/application/services/offline_backup_data_store.dart';
import 'package:memora/application/services/offline_backup_restore_journal_storage.dart';
import 'package:memora/application/services/offline_backup_restore_sync_storage.dart';
import 'package:memora/application/services/offline_backup_settings_storage.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

class SqliteOfflineBackupDataStore implements OfflineBackupDataStore {
  const SqliteOfflineBackupDataStore({
    required this.database,
    required this.currentMemberStorage,
    required this.settingsStorage,
    required this.restoreJournalStorage,
    required this.restoreSyncStorage,
  });

  final OfflineDatabase database;
  final OfflineBackupCurrentMemberStorage currentMemberStorage;
  final OfflineBackupSettingsStorage settingsStorage;
  final OfflineBackupRestoreJournalStorage restoreJournalStorage;
  final OfflineBackupRestoreSyncStorage restoreSyncStorage;

  static const _deleteOrder = <String>[
    'calendar_event_overrides',
    'calendar_events',
    'calendar_labels',
    'tasks',
    'itinerary_items',
    'member_events',
    'group_events',
    'dvc_point_contracts',
    'dvc_limited_points',
    'dvc_point_usages',
    'trip_entries',
    'group_members',
    'groups',
    'members',
  ];

  static const _insertOrder = <String>[
    'members',
    'groups',
    'calendar_labels',
    'calendar_events',
    'calendar_event_overrides',
    'group_members',
    'trip_entries',
    'tasks',
    'itinerary_items',
    'member_events',
    'group_events',
    'dvc_point_contracts',
    'dvc_limited_points',
    'dvc_point_usages',
  ];

  @override
  Future<OfflineBackupSnapshot> exportSnapshot() =>
      database.readTransaction(_exportSnapshotWithoutBackupLock);

  Future<OfflineBackupSnapshot> _exportSnapshotWithoutBackupLock() async {
    final currentMember = await currentMemberStorage.load();
    final settings = await settingsStorage.load();
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in OfflineBackupSnapshot.tableNames) {
      tables[table] = await database.rows(table);
    }
    return OfflineBackupSnapshot(
      formatVersion: OfflineBackupSnapshot.currentFormatVersion,
      databaseSchemaVersion: database.schemaVersion,
      currentMember: currentMember,
      settings: settings,
      tables: tables,
    );
  }

  @override
  Future<void> restoreSnapshot(OfflineBackupSnapshot snapshot) async {
    validateSnapshot(snapshot);
    await database.backupRestoreExclusive(() async {
      await _recoverPendingRestoreWithoutBackupLock();
      final previousSnapshot = await database.transaction(
        _exportSnapshotWithoutBackupLock,
      );
      await restoreJournalStorage.save(previousSnapshot);
      try {
        await _replaceSnapshot(snapshot);
        await restoreSyncStorage.markPending();
        await restoreJournalStorage.clear();
      } catch (error, stackTrace) {
        await _replaceSnapshot(previousSnapshot);
        await restoreJournalStorage.clear();
        await restoreSyncStorage.clear();
        Error.throwWithStackTrace(error, stackTrace);
      }
    });
  }

  Future<void> recoverPendingRestore() =>
      database.backupRestoreExclusive(_recoverPendingRestoreWithoutBackupLock);

  Future<void> _recoverPendingRestoreWithoutBackupLock() async {
    final previousSnapshot = await restoreJournalStorage.load();
    if (previousSnapshot == null) return;
    _validateSnapshot(previousSnapshot, requireCurrentMember: false);
    await _replaceSnapshot(previousSnapshot);
    await restoreJournalStorage.clear();
  }

  Future<void> _replaceSnapshot(OfflineBackupSnapshot snapshot) async {
    final previousMember = await currentMemberStorage.load();
    final previousSettings = await settingsStorage.load();
    try {
      await database.transaction(() async {
        await database.customStatement('PRAGMA defer_foreign_keys = ON');
        for (final table in _deleteOrder) {
          await database.customStatement('DELETE FROM "$table"');
        }
        for (final table in _insertOrder) {
          for (final row in snapshot.tables[table]!) {
            await database.insertRow(table, row);
          }
        }
        await currentMemberStorage.save(snapshot.currentMember);
        await settingsStorage.save(snapshot.settings);
      });
    } catch (_) {
      await _restoreExternalState(previousMember, previousSettings);
      rethrow;
    }
  }

  @override
  void validateSnapshot(OfflineBackupSnapshot snapshot) =>
      _validateSnapshot(snapshot, requireCurrentMember: true);

  void _validateSnapshot(
    OfflineBackupSnapshot snapshot, {
    required bool requireCurrentMember,
  }) {
    if (snapshot.formatVersion != OfflineBackupSnapshot.currentFormatVersion) {
      throw OfflineBackupUnsupportedVersionException(
        '未対応のバックアップ形式です: ${snapshot.formatVersion}',
      );
    }
    if (snapshot.databaseSchemaVersion != database.schemaVersion) {
      throw OfflineBackupUnsupportedVersionException(
        '未対応のDBスキーマです: ${snapshot.databaseSchemaVersion}',
      );
    }
    if (!AndroidWidgetUpdateInterval.values.any(
      (interval) =>
          interval.duration.inMinutes ==
          snapshot.settings.androidWidgetUpdateIntervalMinutes,
    )) {
      throw const FormatException('バックアップのウィジェット更新間隔が不正です。');
    }
    final expectedTables = {...OfflineBackupSnapshot.tableNames};
    if (snapshot.tables.keys.toSet().difference(expectedTables).isNotEmpty ||
        expectedTables.difference(snapshot.tables.keys.toSet()).isNotEmpty) {
      throw const FormatException('バックアップのテーブル構成が不正です。');
    }
    final events = snapshot.tables['calendar_events']!;
    final overrides = snapshot.tables['calendar_event_overrides']!;
    final labels = snapshot.tables['calendar_labels']!;
    for (final override in overrides) {
      if (!events.any(
        (event) =>
            event['id'] == override['event_id'] &&
            event['group_id'] == override['group_id'] &&
            event['recurrence_rule'] != null,
      )) {
        throw const FormatException('上書き対象の系列が存在しません。');
      }
    }
    for (final row in events) {
      final dto = SqliteCalendarEventMapper.fromRow(
        row,
        overrides: overrides
            .where((v) => v['event_id'] == row['id'])
            .map(
              (v) => CalendarOverrideMapper.fromRow(v, row['is_all_day'] == 1),
            )
            .toList(),
      );
      final event = CalendarEventMapper.toEntity(dto);
      validateCalendarRecurrence(event);
      for (final labelId in {
        event.labelId,
        ...event.overrides.where((v) => !v.isCancelled).map((v) => v.labelId!),
      }) {
        if (!labels.any(
          (label) =>
              label['id'] == labelId && label['group_id'] == event.groupId,
        )) {
          throw const FormatException('予定の色ラベルが不正です。');
        }
      }
    }
    final memberExists = snapshot.tables['members']!.any(
      (row) =>
          row['id'] == snapshot.currentMember.id &&
          row['account_id'] == snapshot.currentMember.accountId,
    );
    if (requireCurrentMember && !memberExists) {
      throw const FormatException('バックアップに端末内本人が含まれていません。');
    }
  }

  Future<void> _restoreExternalState(
    OfflineBackupCurrentMember member,
    OfflineBackupSettings settings,
  ) async {
    Object? firstError;
    StackTrace? firstStackTrace;
    try {
      await currentMemberStorage.save(member);
    } catch (error, stackTrace) {
      firstError = error;
      firstStackTrace = stackTrace;
    }
    try {
      await settingsStorage.save(settings);
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }
}
