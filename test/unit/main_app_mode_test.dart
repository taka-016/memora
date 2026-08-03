import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _mainPath = 'lib/main.dart';

void main() {
  test('外部SDKの初期化前にビルド情報からアプリモードを決定する', () {
    final source = File(_mainPath).readAsStringSync();
    final configurationIndex = source.indexOf(
      'AppModeBuildConfiguration.fromEnvironment()',
    );
    final resolverIndex = source.indexOf('AppModeResolver');
    final firebaseIndex = source.indexOf('Firebase.initializeApp');

    expect(configurationIndex, isNonNegative);
    expect(resolverIndex, greaterThan(configurationIndex));
    expect(firebaseIndex, greaterThan(resolverIndex));
  });

  test('起動ログから指定値と決定したモードを確認できる', () {
    final source = File(_mainPath).readAsStringSync();

    expect(source, contains('MEMORA_APP_MODE='));
    expect(source, contains('appMode.name'));
  });
}
