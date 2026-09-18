import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';

class EncryptedOfflineBackupCodec {
  EncryptedOfflineBackupCodec({
    this.argon2Memory = 64 * 1024,
    this.argon2Iterations = 3,
    this.argon2Parallelism = 1,
  });

  static const _fileType = 'memora-offline-backup';
  static const _version = 1;
  static final _associatedData = utf8.encode('$_fileType:$_version');

  final int argon2Memory;
  final int argon2Iterations;
  final int argon2Parallelism;

  Future<Uint8List> encode(
    OfflineBackupSnapshot snapshot,
    String password,
  ) async {
    if (password.isEmpty) {
      throw ArgumentError.value(password, 'password', 'パスワードを入力してください。');
    }
    final salt = _randomBytes(16);
    final cipher = AesGcm.with256bits();
    final secretKey = await _deriveKey(
      password,
      salt,
      memory: argon2Memory,
      iterations: argon2Iterations,
      parallelism: argon2Parallelism,
    );
    final secretBox = await cipher.encrypt(
      utf8.encode(jsonEncode(snapshot.toJson())),
      secretKey: secretKey,
      aad: _associatedData,
    );
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'type': _fileType,
          'version': _version,
          'kdf': 'argon2id',
          'memory': argon2Memory,
          'iterations': argon2Iterations,
          'parallelism': argon2Parallelism,
          'salt': base64Encode(salt),
          'cipher': 'aes-256-gcm',
          'nonce': base64Encode(secretBox.nonce),
          'cipherText': base64Encode(secretBox.cipherText),
          'mac': base64Encode(secretBox.mac.bytes),
        }),
      ),
    );
  }

  Future<OfflineBackupSnapshot> decode(List<int> bytes, String password) async {
    final Map<String, dynamic> envelope;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }
      envelope = decoded;
    } on OfflineBackupUnsupportedVersionException {
      rethrow;
    } catch (_) {
      throw const FormatException('バックアップファイルを読み込めませんでした。');
    }
    if (envelope['type'] != _fileType || envelope['version'] != _version) {
      throw OfflineBackupUnsupportedVersionException(
        '未対応のバックアップファイルです: ${envelope['version']}',
      );
    }
    if (envelope['kdf'] != 'argon2id' || envelope['cipher'] != 'aes-256-gcm') {
      throw const OfflineBackupUnsupportedVersionException('未対応の暗号化方式です。');
    }

    try {
      final memory = _boundedInt(envelope['memory'], 8, 128 * 1024);
      final iterations = _boundedInt(envelope['iterations'], 1, 10);
      final parallelism = _boundedInt(envelope['parallelism'], 1, 4);
      final salt = base64Decode(envelope['salt'] as String);
      if (salt.length != 16) throw const FormatException();
      final nonce = base64Decode(envelope['nonce'] as String);
      final cipherText = base64Decode(envelope['cipherText'] as String);
      final mac = base64Decode(envelope['mac'] as String);
      final cipher = AesGcm.with256bits();
      if (nonce.length != cipher.nonceLength ||
          mac.length != cipher.macAlgorithm.macLength) {
        throw const FormatException();
      }
      final secretKey = await _deriveKey(
        password,
        salt,
        memory: memory,
        iterations: iterations,
        parallelism: parallelism,
      );
      final clearText = await cipher.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: secretKey,
        aad: _associatedData,
      );
      final snapshot = jsonDecode(utf8.decode(clearText));
      if (snapshot is! Map<String, dynamic>) throw const FormatException();
      return OfflineBackupSnapshot.fromJson(snapshot);
    } on OfflineBackupUnsupportedVersionException {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw const OfflineBackupAuthenticationException();
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('バックアップファイルを読み込めませんでした。');
    }
  }

  Future<SecretKey> _deriveKey(
    String password,
    List<int> salt, {
    required int memory,
    required int iterations,
    required int parallelism,
  }) => Argon2id(
    memory: memory,
    parallelism: parallelism,
    iterations: iterations,
    hashLength: 32,
  ).deriveKeyFromPassword(password: password, nonce: salt);

  int _boundedInt(Object? value, int minimum, int maximum) {
    if (value is! int || value < minimum || value > maximum) {
      throw const FormatException('バックアップの暗号化パラメータが不正です。');
    }
    return value;
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
