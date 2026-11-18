import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:memora/infrastructure/config/firestore_emulator_configuration.dart';
import 'package:memora/infrastructure/services/firestore_read_probe.dart';

class FirestoreReadRegressionSession {
  FirestoreReadRegressionSession._(this._operationFile, this.runId);
  static Future<FirestoreReadRegressionSession>? _connection;
  final File _operationFile;
  final String runId;
  Future<void> _pending = Future.value();
  Object? _failure;

  static Future<FirestoreReadRegressionSession> connect() =>
      _connection ??= _connect();

  static Future<FirestoreReadRegressionSession> _connect() async {
    if (FirestoreEmulatorConfiguration.fromEnvironment() == null) {
      throw StateError('読み取り回帰テスト専用ビルドが必要です');
    }
    const runId = String.fromEnvironment('MEMORA_TEST_RUN_ID');
    if (runId.isEmpty) throw StateError('テストの実行IDが必要です');
    final directory = await getApplicationSupportDirectory();
    final operationFile = File('${directory.path}/firestore-read-operation');
    if (!await operationFile.exists()) {
      await operationFile.writeAsString('bootstrap', flush: true);
    }
    final session = FirestoreReadRegressionSession._(operationFile, runId);
    FirestoreReadProbe.current = FirestoreReadProbe(
      runId: runId,
      operationId: operationFile.readAsStringSync,
      emit: session._emit,
    );
    return session;
  }

  void _emit(Map<String, Object?> event) {
    _pending = _enqueue(_pending, event);
  }

  Future<void> _enqueue(
    Future<void> previous,
    Map<String, Object?> event,
  ) async {
    await previous;
    if (_failure != null) return;
    try {
      await request('POST', '/event', event);
    } catch (error) {
      _failure = error;
    }
  }

  Future<void> flush() async {
    await _pending;
    if (_failure != null) throw StateError('計測の集約に失敗しました: $_failure');
  }

  Future<void> begin(String id) async {
    await flush();
    await _operationFile.writeAsString(id, flush: true);
    await request('POST', '/begin', {'id': id});
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, [
    Object? body,
  ]) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.openUrl(
        method,
        Uri.http('127.0.0.1:8765', path),
      );
      request.headers.set('X-Memora-Run', runId);
      request.headers.contentType = ContentType.json;
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final text = await utf8.decoder.bind(response).join();
      if (response.statusCode != 200) {
        throw HttpException('計測集約: ${response.statusCode} $text');
      }
      return jsonDecode(text) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }
}
