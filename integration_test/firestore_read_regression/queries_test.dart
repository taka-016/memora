import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memora/composition_root/app_composition_root.dart';
import 'package:memora/infrastructure/services/firestore_read_regression_session.dart';

import 'query_actions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('外部JSONの期待結果と実SDK読み取り予算を照合する', (tester) async {
    await tester.runAsync(() async {
      final session = await FirestoreReadRegressionSession.connect();
      final bundle = await session.request('GET', '/bundle');
      final scenario = bundle['scenario'] as Map<String, dynamic>;
      final root = AppCompositionRoot.fromBuildConfiguration();
      await root.initialize();
      expect(
        FirebaseFirestore.instance.app.options.projectId,
        bundle['projectId'],
      );
      final container = root.createContainer();
      try {
        for (final raw in scenario['operations'] as List) {
          final operation = raw as Map<String, dynamic>;
          await session.begin(operation['id'] as String);
          try {
            final actual = await executeQueryAction(
              operation['action'] as String,
              operation['parameters'] as Map<String, dynamic>,
              bundle['dataset'] as Map<String, dynamic>,
              container,
            ).timeout(const Duration(seconds: 30));
            expect(
              actual,
              operation['expect'],
              reason: operation['id'] as String,
            );
            await session.flush();
            await session.request('POST', '/operation', {
              'id': operation['id'],
              'status': 'passed',
              'actual': actual,
            });
          } catch (error) {
            await session.flush();
            await session.request('POST', '/operation', {
              'id': operation['id'],
              'status': 'failed',
              'error': error.toString(),
            });
            rethrow;
          }
        }
        expect(FirebaseAuth.instance.currentUser, isNull);
        await session.request('POST', '/completed', {
          'scenario': scenario['id'],
        });
      } finally {
        container.dispose();
        await session.flush();
      }
    });
  });
}
