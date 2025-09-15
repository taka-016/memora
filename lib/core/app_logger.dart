import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

late final Logger logger;

Future<void> initLogger() async {
  logger = Logger(
    printer: PrettyPrinter(),
    output: MultiOutput([
      if (!kReleaseMode) ConsoleOutput(),
      CrashlyticsOutput(),
      // 必要な場合はファイル保存を有効化する
      // FileOutput(),
    ]),
  );
}

class ConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      debugPrint(line);
    }
  }
}

class CrashlyticsOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      FirebaseCrashlytics.instance.log(line);
    }
  }
}

class FileOutput extends LogOutput {
  IOSink? _sink;

  Future<void> _init() async {
    if (_sink != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/app.log');
    _sink = file.openWrite(mode: FileMode.append);
  }

  @override
  void output(OutputEvent event) async {
    await _init();
    for (var line in event.lines) {
      _sink?.writeln(line);
    }
  }
}
