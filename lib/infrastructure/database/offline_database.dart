import 'dart:io';

import 'package:drift/drift.dart' hide OrderBy;
import 'package:drift/native.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/transactions/read_transaction.dart';
import 'package:path_provider/path_provider.dart';

part 'offline_database.g.dart';

@DriftDatabase(include: {'offline_schema.drift'})
class OfflineDatabase extends _$OfflineDatabase implements ReadTransaction {
  OfflineDatabase(super.executor, [this._backupLockFile]);

  final Future<File> Function()? _backupLockFile;

  factory OfflineDatabase.device({
    Future<Directory> Function() directory = getApplicationSupportDirectory,
  }) => OfflineDatabase(
    LazyDatabase(() async {
      final databaseDirectory = await directory();
      await databaseDirectory.create(recursive: true);
      return NativeDatabase.createInBackground(
        File('${databaseDirectory.path}/memora.sqlite'),
        setup: (database) {
          database.execute('PRAGMA busy_timeout = 5000');
          database.execute('PRAGMA journal_mode = WAL');
        },
      );
    }),
    () async {
      final databaseDirectory = await directory();
      await databaseDirectory.create(recursive: true);
      return File('${databaseDirectory.path}/memora_backup_restore.lock');
    },
  );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      throw StateError('未対応のDBバージョンです: $from → $to');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  String _column(String field) => field.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match[0]!.toLowerCase()}',
  );

  Future<void> initialize() async {
    await customSelect('SELECT 1').get();
  }

  @override
  Future<T> execute<T>(Future<T> Function() action) async => _withBackupLock(
    FileLock.shared,
    () => exclusively(() async {
      // 通常のtransactionはBEGIN IMMEDIATEで別接続の書き込みもロックする。
      await customStatement('BEGIN DEFERRED');
      try {
        return await action();
      } finally {
        await customStatement('ROLLBACK');
      }
    }),
  );

  Future<T> readTransaction<T>(Future<T> Function() action) => execute(action);

  Future<T> backupRestoreTransaction<T>(Future<T> Function() action) =>
      _withBackupLock(FileLock.exclusive, () => transaction(action));

  Future<T> backupRestoreExclusive<T>(Future<T> Function() action) =>
      _withBackupLock(FileLock.exclusive, action);

  Future<T> _withBackupLock<T>(
    FileLock lock,
    Future<T> Function() action,
  ) async {
    final lockFile = _backupLockFile;
    if (lockFile == null) return action();
    final file = await lockFile();
    final handle = await file.open(mode: FileMode.append);
    try {
      await handle.lock(lock);
      return await action();
    } finally {
      await handle.unlock();
      await handle.close();
    }
  }

  Future<List<Map<String, Object?>>> rows(
    String table, {
    String? where,
    List<Object> args = const [],
    List<OrderBy>? orderBy,
  }) async {
    final columns = allTables
        .firstWhere((t) => t.actualTableName == table)
        .$columns
        .map((c) => c.$name)
        .toSet();
    final orders = orderBy ?? const <OrderBy>[];
    for (final order in orders) {
      if (!columns.contains(_column(order.field))) {
        throw ArgumentError('未対応の並び替え項目です: ${order.field}');
      }
    }
    final sorting = orders.isEmpty
        ? ''
        : ' ORDER BY ${orders.map((o) => '"${_column(o.field)}" ${o.descending ? 'DESC' : 'ASC'}').join(', ')}';
    final result = await customSelect(
      'SELECT * FROM "$table"${where == null ? '' : ' WHERE $where'}$sorting',
      variables: args.map((v) => Variable(v)).toList(),
    ).get();
    return result.map((r) => r.data).toList();
  }

  Future<void> insertRow(String table, Map<String, Object?> row) async {
    await customStatement(
      'INSERT INTO "$table" (${row.keys.map((k) => '"$k"').join(', ')}) VALUES (${List.filled(row.length, '?').join(', ')})',
      row.values.toList(),
    );
  }

  Future<void> updateRow(
    String table,
    String id,
    Map<String, Object?> row,
  ) async {
    final count = await customUpdate(
      'UPDATE "$table" SET ${row.keys.map((k) => '"$k" = ?').join(', ')} WHERE id = ?',
      variables: [...row.values.map((v) => Variable(v)), Variable(id)],
    );
    if (count == 0) throw StateError('更新対象が存在しません: $table/$id');
  }

  Future<void> deleteRows(String table, String field, String value) async {
    await customStatement('DELETE FROM "$table" WHERE "$field" = ?', [value]);
  }
}
