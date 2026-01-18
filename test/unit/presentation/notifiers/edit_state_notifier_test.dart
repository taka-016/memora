import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/notifiers/edit_state_notifier.dart';

void main() {
  group('EditStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態では変更なしである', () {
      final state = container.read(editStateNotifierProvider);

      expect(state.isDirty, isFalse);
    });

    test('変更状態を更新できる', () {
      final notifier = container.read(editStateNotifierProvider.notifier);

      notifier.setDirty(true);

      final state = container.read(editStateNotifierProvider);
      expect(state.isDirty, isTrue);
    });

    test('resetで変更状態を初期化できる', () {
      final notifier = container.read(editStateNotifierProvider.notifier);

      notifier.setDirty(true);
      notifier.reset();

      final state = container.read(editStateNotifierProvider);
      expect(state.isDirty, isFalse);
    });
  });
}
