import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('外部SDKの初期化と具象実装はInfrastructure層へ閉じ込める', () {
    final paths = [
      'lib/main.dart',
      'lib/core/app_logger.dart',
      'lib/core/time/app_clock.dart',
      'lib/infrastructure/android_widget/android_widget_background_update.dart',
      'lib/infrastructure/android_widget/android_widget_interactivity_callback.dart',
    ];
    final violations = <String>[];
    for (final path in paths) {
      final source = File(path).readAsStringSync();
      for (final sdk in [
        'firebase_core/',
        'firebase_crashlytics/',
        'cloud_firestore/',
        'ntp/',
        'FirestoreTripEntryQueryService(',
        'FirestoreItineraryItemQueryService(',
      ]) {
        if (source.contains(sdk)) violations.add('$path: $sdk');
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('オンライン版はプロセス起動時のFirebase初期化を妨げない', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(
      manifest,
      isNot(contains('com.google.firebase.provider.FirebaseInitProvider')),
    );
  });

  test('オフライン版はFirebaseを自動初期化しない', () {
    final manifest = File('android/app/src/offline/AndroidManifest.xml')
        .readAsStringSync();
    expect(
      manifest,
      matches(
        RegExp(
          r'<provider\s+android:name="com.google.firebase.provider.FirebaseInitProvider"[^>]*tools:node="remove"',
        ),
      ),
    );
  });

  test('起動前のCrashlytics自動収集を無効化する', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(
      manifest,
      matches(
        RegExp(
          r'android:name="firebase_crashlytics_collection_enabled"\s+android:value="false"',
        ),
      ),
    );
  });
}
