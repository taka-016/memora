import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:memora/application/services/offline_backup_file_selector.dart';

class FilePickerOfflineBackupFileSelector implements OfflineBackupFileSelector {
  const FilePickerOfflineBackupFileSelector();

  @override
  Future<Uint8List?> pick() async {
    final file = await FilePicker.pickFile(
      dialogTitle: '復元するバックアップを選択',
      type: FileType.custom,
      allowedExtensions: const ['memora'],
    );
    return file?.readAsBytes();
  }

  @override
  Future<bool> save(Uint8List bytes, {required String suggestedName}) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: 'バックアップの保存先を選択',
      fileName: suggestedName,
      bytes: bytes,
      mimeType: 'application/octet-stream',
    );
    return uri != null;
  }
}
