import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _rootPath = 'lib/composition_root/app_composition_root.dart';
const _bootstrapPath = 'lib/composition_root/app_bootstrap.dart';

void main() {
  test('ビルド情報を解析してからモードを判定する', () {
    final source = File(_rootPath).readAsStringSync();
    final configurationIndex = source.indexOf(
      'AppModeBuildConfiguration.fromEnvironment()',
    );
    final resolverIndex = source.indexOf('const AppModeResolver().resolve');
    expect(configurationIndex, isNonNegative);
    expect(resolverIndex, greaterThan(configurationIndex));
  });

  test('起動ログから指定値と決定したモードを確認できる', () {
    final source = File(_bootstrapPath).readAsStringSync();
    expect(source, contains('MEMORA_APP_MODE='));
    expect(source, contains('root.mode.name'));
  });

  test('モードに応じた初期化後に起動ログを出力する', () {
    final source = File(_bootstrapPath).readAsStringSync();
    final initializationIndex = source.indexOf('await root.initialize()');
    final logIndex = source.indexOf('root.services.log.i(');
    expect(initializationIndex, isNonNegative);
    expect(logIndex, greaterThan(initializationIndex));
  });
}
