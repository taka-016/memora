import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

class FileAndroidWidgetCacheGenerationLock {
  const FileAndroidWidgetCacheGenerationLock(this._directoryPath);

  static const lockFileName = 'memora_widget_cache_generation.lock';
  static const lockDatabaseFileName =
      'memora_widget_cache_generation_lock.sqlite';
  static const _retryInterval = Duration(milliseconds: 10);
  static const _sqliteBusy = 5;
  static const _sqliteLocked = 6;

  final String _directoryPath;

  Future<T> synchronized<T>(Future<T> Function() action) async {
    final directory = Directory(_directoryPath);
    await directory.create(recursive: true);
    await _waitForLegacyLock(directory);
    final database = await _acquireDatabaseLock(directory);
    try {
      return await action();
    } finally {
      try {
        await database.runCustom('ROLLBACK', const []);
      } finally {
        await database.close();
      }
    }
  }

  Future<NativeDatabase> _acquireDatabaseLock(Directory directory) async {
    final lockFile = File('${directory.path}/$lockDatabaseFileName');
    while (true) {
      final database = NativeDatabase(lockFile, enableMigrations: false);
      try {
        await database.ensureOpen(const _LockDatabaseUser());
        await database.runCustom('BEGIN IMMEDIATE', const []);
        return database;
      } on SqliteException catch (error) {
        await database.close();
        if (!_isLockContention(error)) {
          rethrow;
        }
        await Future<void>.delayed(_retryInterval);
      } catch (_) {
        await database.close();
        rethrow;
      }
    }
  }

  bool _isLockContention(SqliteException error) =>
      error.resultCode == _sqliteBusy || error.resultCode == _sqliteLocked;

  Future<void> _waitForLegacyLock(Directory directory) async {
    final path = '${directory.path}/$lockFileName';
    while (true) {
      final type = await FileSystemEntity.type(path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        return;
      }
      String owner;
      try {
        owner = type == FileSystemEntityType.link
            ? await Link(path).target()
            : await File(path).readAsString();
      } on FileSystemException {
        continue;
      }
      if (await _ownerIsRunning(owner)) {
        await Future<void>.delayed(_retryInterval);
        continue;
      }
      try {
        if (type == FileSystemEntityType.link) {
          await Link(path).delete();
        } else {
          await File(path).delete();
        }
      } on FileSystemException {
        // 別処理の旧ロック回収と競合した場合は再確認する。
      }
    }
  }

  Future<bool> _ownerIsRunning(String owner) async {
    final ownerProcessId = int.tryParse(owner.split('-').first);
    return ownerProcessId != null &&
        await Directory('/proc/$ownerProcessId').exists();
  }
}

class _LockDatabaseUser implements QueryExecutorUser {
  const _LockDatabaseUser();

  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) =>
      Future.value();
}
