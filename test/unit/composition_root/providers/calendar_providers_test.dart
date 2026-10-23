import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

import '../../../helpers/test_exception.dart';

void main() {
  test('オフラインの監視依存はFirestoreを初期化せず単発取得を選ぶ', () {
    final container = ProviderContainer(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.offline),
        firebaseFirestoreProvider.overrideWith(
          (ref) => throw TestException('Firestoreを参照してはいけません'),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(watchCalendarEventsUsecaseProvider), isNull);
    expect(container.read(watchCalendarLabelsUsecaseProvider), isNull);
  });
}
