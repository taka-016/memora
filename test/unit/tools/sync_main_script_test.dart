import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory testDirectory;
  late Directory repository;

  ProcessResult git(List<String> arguments) =>
      Process.runSync('git', arguments, workingDirectory: repository.path);

  void runGit(List<String> arguments) {
    final result = git(arguments);
    expect(result.exitCode, 0, reason: result.stderr as String);
  }

  void createDeletedUpstream(String branch) {
    runGit(['checkout', '-b', branch]);
    runGit(['push', '-u', 'origin', branch]);
    runGit(['push', 'origin', '--delete', branch]);
  }

  ProcessResult runScript() => Process.runSync('bash', [
    '${repository.path}/sync_main.sh',
  ], workingDirectory: testDirectory.path);

  bool branchExists(String branch) =>
      git(['show-ref', '--verify', 'refs/heads/$branch']).exitCode == 0;

  setUp(() {
    testDirectory = Directory.systemTemp.createTempSync('memora_sync_main_');
    repository = Directory('${testDirectory.path}/repository')..createSync();
    runGit(['init', '--bare', '${testDirectory.path}/remote.git']);
    runGit(['init', '-b', 'main']);
    runGit(['config', 'user.name', 'テスト']);
    runGit(['config', 'user.email', 'test@example.invalid']);
    runGit(['commit', '--allow-empty', '-m', '初期状態']);
    runGit(['remote', 'add', 'origin', '${testDirectory.path}/remote.git']);
    runGit(['push', '-u', 'origin', 'main']);
    File('sync_main.sh').copySync('${repository.path}/sync_main.sh');
  });

  tearDown(() {
    testDirectory.deleteSync(recursive: true);
  });

  test('mainへ切り替えて更新しマージ済みの削除済み追跡ブランチだけを整理する', () {
    createDeletedUpstream('merged');
    runGit(['commit', '--allow-empty', '-m', 'マージ対象']);
    runGit(['checkout', 'main']);
    runGit(['merge', '--ff-only', 'merged']);
    runGit(['push', 'origin', 'main']);
    runGit(['reset', '--hard', 'HEAD~1']);
    runGit(['checkout', '-b', 'local-only']);

    final result = runScript();

    expect(result.exitCode, 0, reason: result.stderr as String);
    expect(git(['branch', '--show-current']).stdout, 'main\n');
    expect(
      git(['rev-parse', 'HEAD']).stdout,
      git(['rev-parse', 'origin/main']).stdout,
    );
    expect(branchExists('merged'), isFalse);
    expect(branchExists('local-only'), isTrue);
    expect(runScript().exitCode, 0);
  });

  test('追跡先が削除されても未マージのローカルコミットを保持する', () {
    createDeletedUpstream('unmerged');
    runGit(['commit', '--allow-empty', '-m', 'ローカルにだけある変更']);
    final commit = git(['rev-parse', 'HEAD']).stdout;

    final result = runScript();

    expect(result.exitCode, isNot(0));
    expect(branchExists('unmerged'), isTrue);
    expect(git(['rev-parse', 'unmerged']).stdout, commit);
  });

  test('別worktreeで使用中のブランチを保持し他の削除対象は整理する', () {
    createDeletedUpstream('in-use');
    runGit(['checkout', 'main']);
    runGit(['worktree', 'add', '${testDirectory.path}/worktree', 'in-use']);
    createDeletedUpstream('merged');

    final result = runScript();

    expect(result.exitCode, 0, reason: result.stderr as String);
    expect(branchExists('in-use'), isTrue);
    expect(branchExists('merged'), isFalse);
  });
}
