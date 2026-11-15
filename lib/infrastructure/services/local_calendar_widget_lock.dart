import 'dart:async';
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
  static final _pending = <String, Future<void>>{};

  Future<T> run<T>(String name, Future<T> Function() action) async {
    final directory = await _directory();
    await directory.create(recursive: true);
    final file = File('${directory.path}/calendar_widget_$name.lock.sqlite');
    final key = file.absolute.path;
    final previous = _pending[key];
    final released = Completer<void>();
    final pending = released.future;
    _pending[key] = pending;
    try {
      await previous;
      return await _run(file, action);
    } finally {
      released.complete();
      if (identical(_pending[key], pending)) _pending.remove(key);
    }
  }

  Future<T> _run<T>(File file, Future<T> Function() action) async {
    final timeoutMillis = busyTimeout.inMilliseconds;
    final executor = NativeDatabase.createInBackground(
      file,
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
