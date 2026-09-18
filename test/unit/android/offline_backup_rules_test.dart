import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android 11以前と12以降で自動バックアップと端末間転送から内部データを除外する', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final legacyRules = File(
      'android/app/src/main/res/xml/backup_rules.xml',
    ).readAsStringSync();
    final extractionRules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    for (final domain in ['root', 'file', 'database', 'sharedpref']) {
      expect(legacyRules, contains('domain="$domain" path="."'));
      expect(
        RegExp('domain="$domain" path="\\."').allMatches(extractionRules),
        hasLength(2),
      );
    }
    expect(extractionRules, contains('<cloud-backup'));
    expect(extractionRules, contains('<device-transfer>'));
  });
}
