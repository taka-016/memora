import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Firestore設定テスト', () {
    test('SettingsオブジェクトのpersistenceEnabledがfalseになること', () {
      // Settingsオブジェクトを作成
      const settings = Settings(persistenceEnabled: false);

      // persistenceEnabledがfalseであることを確認
      expect(settings.persistenceEnabled, false);
    });
  });
}
