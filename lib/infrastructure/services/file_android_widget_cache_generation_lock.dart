import 'dart:io';
import 'dart:math';

class FileAndroidWidgetCacheGenerationLock {
  const FileAndroidWidgetCacheGenerationLock(this._directoryPath);

  static const lockFileName = 'memora_widget_cache_generation.lock';

  final String _directoryPath;

  Future<T> synchronized<T>(Future<T> Function() action) async {
    final directory = Directory(_directoryPath);
    await directory.create(recursive: true);
    final lock = Link('${directory.path}/$lockFileName');
    final owner = _createOwner();
    while (true) {
      try {
        await lock.create(owner);
        break;
      } on FileSystemException {
        await _deleteStaleLock(lock);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }
    try {
      return await action();
    } finally {
      await _releaseIfOwned(lock, owner);
    }
  }

  String _createOwner() {
    final random = Random.secure();
    return '$pid-${random.nextInt(1 << 32)}-${random.nextInt(1 << 32)}';
  }

  Future<void> _deleteStaleLock(Link lock) async {
    try {
      final type = await FileSystemEntity.type(lock.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        return;
      }
      if (type != FileSystemEntityType.link) {
        await File(lock.path).delete();
        return;
      }
      final owner = await lock.target();
      final ownerProcessId = int.tryParse(owner.split('-').first);
      final ownerIsRunning =
          ownerProcessId != null &&
          await Directory('/proc/$ownerProcessId').exists();
      if (!ownerIsRunning && await lock.target() == owner) {
        await lock.delete();
      }
    } on FileSystemException {
      // 所有者の解放や別処理の回収と競合した場合は次の取得で再確認する。
    }
  }

  Future<void> _releaseIfOwned(Link lock, String owner) async {
    try {
      if (await lock.target() == owner) {
        await lock.delete();
      }
    } on FileSystemException {
      // プロセス終了後の回収と競合した場合は処理を継続する。
    }
  }
}
