import 'dart:convert';
import 'dart:io';

import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/application/services/offline_backup_restore_journal_storage.dart';
import 'package:path_provider/path_provider.dart';

class LocalOfflineBackupRestoreJournalStorage
    implements OfflineBackupRestoreJournalStorage {
  LocalOfflineBackupRestoreJournalStorage({
    Future<Directory> Function()? directory,
  }) : _directory = directory ?? getApplicationSupportDirectory;

  static const _version = 1;
  final Future<Directory> Function() _directory;

  @override
  Future<void> save(OfflineBackupSnapshot snapshot) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    try {
      await temporary.writeAsString(
        jsonEncode({'version': _version, 'snapshot': snapshot.toJson()}),
        flush: true,
      );
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  @override
  Future<OfflineBackupSnapshot?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;
    final value = jsonDecode(await file.readAsString());
    if (value is! Map<String, dynamic> ||
        value['version'] != _version ||
        value['snapshot'] is! Map<String, dynamic>) {
      throw const FormatException('復元ジャーナルを読み込めませんでした。');
    }
    return OfflineBackupSnapshot.fromJson(
      value['snapshot'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
    final temporary = File('${file.path}.tmp');
    if (await temporary.exists()) await temporary.delete();
  }

  Future<File> _file() async {
    final directory = await _directory();
    await directory.create(recursive: true);
    return File('${directory.path}/offline_backup_restore_journal.json');
  }
}
