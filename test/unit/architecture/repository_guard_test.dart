import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora_repository_guard_generator/generator.dart';

List<File> _dartFiles(String directory) =>
    Directory(directory)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();

void main() {
  test('全Repositoryの宣言と生成済みガードが一致する', () {
    final sources = {
      for (final file in _dartFiles('lib/domain/repositories'))
        file.path: file.readAsStringSync(),
    };
    expect(
      File('lib/application/decorators/repository_guards.g.dart')
          .readAsStringSync(),
      generateRepositoryGuards(sources, packageName: 'memora'),
    );
  });

  test('具象RepositoryはFactoryとトランザクション内だけで参照する', () {
    const allowed = {
      'lib/infrastructure/factories/repository_factory.dart',
      'lib/infrastructure/transactions/firestore_write_transaction.dart',
      'lib/infrastructure/transactions/sqlite_write_transaction.dart',
    };
    final implementations = <String, String>{};
    for (final file in _dartFiles('lib/infrastructure/repositories')) {
      if (!file.path.endsWith('_repository.dart')) continue;
      for (final match in RegExp(
        r'\bclass\s+([A-Z]\w*)',
      ).allMatches(file.readAsStringSync())) {
        implementations[match.group(1)!] = file.path;
      }
    }
    final violations = <String>[];
    for (final file in _dartFiles('lib')) {
      if (allowed.contains(file.path)) continue;
      final source = file.readAsStringSync();
      for (final implementation in implementations.entries) {
        if (file.path == implementation.value) continue;
        if (RegExp('\\b${implementation.key}\\b').hasMatch(source)) {
          violations.add('${file.path}: ${implementation.key}');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
