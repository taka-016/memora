import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

class LocalCalendarWidgetLock {
  LocalCalendarWidgetLock({
    Future<Directory> Function()? directory,
    this.busyTimeout = const Duration(seconds: 30),
  }) : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;
  final Duration busyTimeout;

  Future<T> run<T>(String name, Future<T> Function() action) async {
    final directory = await _directory();
    await directory.create(recursive: true);
    final timeoutMillis = busyTimeout.inMilliseconds;
    final executor = NativeDatabase.createInBackground(
      File('${directory.path}/calendar_widget_$name.lock.sqlite'),
      setup: (database) =>
          database.execute('PRAGMA busy_timeout = $timeoutMillis'),
    );
    try {
      await executor.ensureOpen(const _LockUser());
      await executor.runCustom('BEGIN IMMEDIATE');
      try {
        return await action();
      } finally {
        await executor.runCustom('ROLLBACK');
      }
    } finally {
      await executor.close();
    }
  }
}

class _LockUser implements QueryExecutorUser {
  const _LockUser();
  @override
  int get schemaVersion => 1;
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
