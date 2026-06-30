import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dev Containerの機密情報管理', () {
    test('envファイルを読み込まずホスト環境変数からGitHubトークンを渡す', () {
      final devcontainerJson =
          jsonDecode(File('.devcontainer/devcontainer.json').readAsStringSync())
              as Map<String, Object?>;

      final runArgs = (devcontainerJson['runArgs'] as List<Object?>?) ?? [];
      expect(runArgs, isNot(contains('--env-file')));
      expect(runArgs, isNot(contains('.devcontainer/.env')));

      expect(devcontainerJson['containerEnv'], {
        'GH_TOKEN': r'${localEnv:GH_TOKEN}',
        'GITHUB_TOKEN': r'${localEnv:GITHUB_TOKEN}',
      });
    });

    test('初期化処理でdevcontainer用envファイルを作成しない', () {
      final initializeScript = File(
        '.devcontainer/initialize.sh',
      ).readAsStringSync();

      expect(initializeScript, isNot(contains('.devcontainer/.env')));
    });

    test('devcontainer用envファイルは明示的にGit管理対象外にする', () {
      final gitignore = File('.gitignore').readAsStringSync();

      expect(gitignore, contains('.devcontainer/.env'));
    });
  });
}
