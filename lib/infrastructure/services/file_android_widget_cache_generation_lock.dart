import 'dart:convert';
import 'dart:io';
import 'dart:math';

class FileAndroidWidgetCacheGenerationLock {
  const FileAndroidWidgetCacheGenerationLock(this._directoryPath);

  static const lockFileName = 'memora_widget_cache_generation.lock';
  static const participantDirectoryName =
      'memora_widget_cache_generation_lock_participants';
  static const _retryInterval = Duration(milliseconds: 10);
  static const _participantExtension = '.participant';

  final String _directoryPath;

  Future<T> synchronized<T>(Future<T> Function() action) async {
    final directory = Directory(_directoryPath);
    await directory.create(recursive: true);
    await _waitForLegacyLock(directory);
    final participants = Directory(
      '${directory.path}/$participantDirectoryName',
    );
    await participants.create(recursive: true);
    final token = _createToken();
    final participant = File(
      '${participants.path}/$token$_participantExtension',
    );
    await _writeState(participant, choosing: true, ticket: 0);
    try {
      final currentParticipants = await _readParticipants(participants);
      final ticket = currentParticipants.fold(
        1,
        (next, other) => other.ticket >= next ? other.ticket + 1 : next,
      );
      await _writeState(participant, choosing: false, ticket: ticket);
      while (await _hasPrecedingParticipant(participants, token, ticket)) {
        await Future<void>.delayed(_retryInterval);
      }
      return await action();
    } finally {
      try {
        await participant.delete();
      } on FileSystemException {
        // 自身の参加ファイルが既に存在しない場合は処理を継続する。
      }
    }
  }

  String _createToken() {
    final random = Random.secure();
    return '$pid-${random.nextInt(1 << 32)}-${random.nextInt(1 << 32)}';
  }

  Future<void> _writeState(
    File participant, {
    required bool choosing,
    required int ticket,
  }) async {
    final temporary = File('${participant.path}.${_createToken()}.tmp');
    await temporary.writeAsString(
      jsonEncode({'choosing': choosing, 'ticket': ticket}),
      flush: true,
    );
    await temporary.rename(participant.path);
  }

  Future<bool> _hasPrecedingParticipant(
    Directory directory,
    String token,
    int ticket,
  ) async {
    final participants = await _readParticipants(directory);
    for (final other in participants) {
      if (other.token == token) {
        continue;
      }
      if (other.choosing ||
          other.ticket < ticket ||
          other.ticket == ticket && other.token.compareTo(token) < 0) {
        return true;
      }
    }
    return false;
  }

  Future<List<_LockParticipant>> _readParticipants(Directory directory) async {
    final participants = <_LockParticipant>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith(_participantExtension)) {
        continue;
      }
      final token = entity.uri.pathSegments.last.replaceFirst(
        _participantExtension,
        '',
      );
      if (!await _ownerIsRunning(token)) {
        continue;
      }
      try {
        final state = jsonDecode(await entity.readAsString());
        if (state is! Map<String, dynamic>) {
          continue;
        }
        participants.add(
          _LockParticipant(
            token: token,
            choosing: state['choosing'] as bool,
            ticket: state['ticket'] as int,
          ),
        );
      } on FileSystemException {
        // 状態ファイルの置換や所有者の解放と競合した場合は再読込する。
      }
    }
    return participants;
  }

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

class _LockParticipant {
  const _LockParticipant({
    required this.token,
    required this.choosing,
    required this.ticket,
  });

  final String token;
  final bool choosing;
  final int ticket;
}
