import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/application/usecases/backup/synchronize_offline_backup_restore_usecase.dart';

void main() {
  const snapshot = OfflineBackupSnapshot(
    formatVersion: 1,
    databaseSchemaVersion: 1,
    currentMember: OfflineBackupCurrentMember(
      id: 'member-1',
      accountId: 'account-1',
      displayName: '本人',
    ),
    settings: OfflineBackupSettings(
      androidWidgetUpdateIntervalMinutes: 360,
      showAge: true,
      showGrade: true,
      showYakudoshi: true,
    ),
    tables: {},
  );

  test('復元後も対象グループが存在する場合は選択日を検証してキャッシュを再生成する', () async {
    String? refreshedGroupId;
    String? refreshedDateId;
    Duration? registeredFrequency;
    final usecase = SynchronizeOfflineBackupRestoreUsecase(
      loadTargetGroupId: () async => 'group-1',
      loadSelectedItineraryDateId: () async => 'date-1',
      targetGroupExists: (memberId, groupId) async =>
          memberId == 'member-1' && groupId == 'group-1',
      clearWidgetCache: () async => fail('キャッシュを解除してはならない'),
      refreshWidgetCache: (groupId, selectedDateId) async {
        refreshedGroupId = groupId;
        refreshedDateId = selectedDateId;
      },
      registerPeriodicUpdateTask: (frequency) async {
        registeredFrequency = frequency;
      },
    );

    await usecase.execute(snapshot);

    expect(refreshedGroupId, 'group-1');
    expect(refreshedDateId, 'date-1');
    expect(registeredFrequency, const Duration(hours: 6));
  });

  test('対象グループが復元データに存在しない場合はウィジェットキャッシュを解除する', () async {
    var cleared = false;
    var refreshed = false;
    final usecase = SynchronizeOfflineBackupRestoreUsecase(
      loadTargetGroupId: () async => 'removed-group',
      loadSelectedItineraryDateId: () async => 'date-1',
      targetGroupExists: (_, _) async => false,
      clearWidgetCache: () async => cleared = true,
      refreshWidgetCache: (_, _) async => refreshed = true,
      registerPeriodicUpdateTask: (_) async {},
    );

    await usecase.execute(snapshot);

    expect(cleared, isTrue);
    expect(refreshed, isFalse);
  });

  test('バックアップに不正な更新間隔が含まれる場合は同期前に拒否する', () async {
    final invalid = OfflineBackupSnapshot(
      formatVersion: snapshot.formatVersion,
      databaseSchemaVersion: snapshot.databaseSchemaVersion,
      currentMember: snapshot.currentMember,
      settings: const OfflineBackupSettings(
        androidWidgetUpdateIntervalMinutes: 2,
        showAge: true,
        showGrade: true,
        showYakudoshi: true,
      ),
      tables: snapshot.tables,
    );
    final usecase = SynchronizeOfflineBackupRestoreUsecase(
      loadTargetGroupId: () async => null,
      loadSelectedItineraryDateId: () async => null,
      targetGroupExists: (_, _) async => true,
      clearWidgetCache: () async {},
      refreshWidgetCache: (_, _) async {},
      registerPeriodicUpdateTask: (_) async {},
    );

    await expectLater(
      usecase.execute(invalid),
      throwsA(isA<FormatException>()),
    );
  });
}
