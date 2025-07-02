import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/services/production_firebase_initializer.dart';
import 'package:memora/domain/services/firebase_initializer.dart';

void main() {
  group('ProductionFirebaseInitializer', () {
    late ProductionFirebaseInitializer initializer;

    setUp(() {
      initializer = ProductionFirebaseInitializer();
    });

    test('FirebaseInitializerインターフェースを実装していること', () {
      expect(initializer, isA<FirebaseInitializer>());
    });

    test('initialize()メソッドが存在すること', () {
      expect(initializer.initialize, isA<Function>());
    });
  });
}