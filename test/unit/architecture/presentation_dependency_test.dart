import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Presentation層はDomain層とInfrastructure層を直接参照しない', () {
    final violations = <String>[];
    final presentationDirectory = Directory('lib/presentation');

    for (final entity in presentationDirectory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final source = entity.readAsStringSync();
      for (final forbiddenLayer in ['domain', 'infrastructure']) {
        if (source.contains("package:memora/$forbiddenLayer/")) {
          violations.add('${entity.path}: $forbiddenLayer');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
