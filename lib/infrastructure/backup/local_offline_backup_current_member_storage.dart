import 'dart:convert';
import 'dart:io';

import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/application/services/offline_backup_current_member_storage.dart';
import 'package:path_provider/path_provider.dart';

class LocalOfflineBackupCurrentMemberStorage
    implements OfflineBackupCurrentMemberStorage {
  LocalOfflineBackupCurrentMemberStorage({
    Future<Directory> Function()? directory,
  }) : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  @override
  Future<OfflineBackupCurrentMember> load() async {
    final file = await _file();
    final value = jsonDecode(await file.readAsString());
    if (value is! Map<String, dynamic> || value['version'] != 1) {
      throw const FormatException('端末内の本人情報を読み込めませんでした。');
    }
    return OfflineBackupCurrentMember.fromJson(value);
  }

  @override
  Future<void> save(OfflineBackupCurrentMember member) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    try {
      await temporary.writeAsString(
        jsonEncode({'version': 1, ...member.toJson()}),
        flush: true,
      );
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<File> _file() async {
    final directory = await _directory();
    await directory.create(recursive: true);
    return File('${directory.path}/offline_current_member.json');
  }
}
