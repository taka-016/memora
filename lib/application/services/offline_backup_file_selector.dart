import 'dart:typed_data';

abstract interface class OfflineBackupFileSelector {
  Future<bool> save(Uint8List bytes, {required String suggestedName});

  Future<Uint8List?> pick();
}
