import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final layer in ['domain', 'application']) {
    test('$layer層は外側の層を参照しない', () {
      final violations = <String>[];
      for (final file in Directory('lib/$layer').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final directives = RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''')
            .allMatches(file.readAsStringSync());
        for (final directive in directives) {
          final uri = directive.group(1)!;
          if ((layer == 'domain' && uri.contains('application/')) ||
              uri.contains('infrastructure/') ||
              uri.contains('presentation/') ||
              uri.contains('composition_root/') ||
              uri.contains('firebase_') ||
              uri.contains('cloud_firestore') ||
              uri.contains('workmanager/') ||
              uri.contains('home_widget/') ||
              uri.contains('shared_preferences/')) {
            violations.add('${file.path}: $uri');
          }
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  }
}
