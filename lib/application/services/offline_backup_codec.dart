import 'dart:typed_data';

import 'package:memora/application/models/offline_backup_snapshot.dart';

abstract interface class OfflineBackupCodec {
  Future<Uint8List> encode(OfflineBackupSnapshot snapshot, String password);

  Future<OfflineBackupSnapshot> decode(List<int> bytes, String password);
}
