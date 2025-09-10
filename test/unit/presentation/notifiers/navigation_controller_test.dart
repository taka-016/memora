import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/notifiers/navigation_notifier.dart';

void main() {
  group('NavigationNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態でグループ年表が選択されている', () {
      // Act
      final state = container.read(navigationNotifierProvider);

      // Assert
      expect(state.selectedItem, NavigationItem.groupTimeline);
    });

    test('ナビゲーション項目を変更できる', () {
      // Arrange
      final notifier = container.read(navigationNotifierProvider.notifier);

      // Act
      notifier.selectItem(NavigationItem.mapDisplay);

      // Assert
      final state = container.read(navigationNotifierProvider);
      expect(state.selectedItem, NavigationItem.mapDisplay);
    });

    test('すべてのナビゲーション項目に変更できる', () {
      // Arrange
      final notifier = container.read(navigationNotifierProvider.notifier);
      final testItems = [
        NavigationItem.groupTimeline,
        NavigationItem.mapDisplay,
        NavigationItem.groupManagement,
        NavigationItem.memberManagement,
        NavigationItem.settings,
        NavigationItem.accountSettings,
      ];

      for (final item in testItems) {
        // Act
        notifier.selectItem(item);

        // Assert
        final state = container.read(navigationNotifierProvider);
        expect(state.selectedItem, item);
      }
    });

    test('状態の変更が通知される', () {
      // Arrange
      final notifier = container.read(navigationNotifierProvider.notifier);
      var notificationCount = 0;

      container.listen<NavigationState>(navigationNotifierProvider, (
        previous,
        next,
      ) {
        notificationCount++;
      });

      // Act
      notifier.selectItem(NavigationItem.mapDisplay);
      notifier.selectItem(NavigationItem.settings);

      // Assert
      expect(notificationCount, 2);
    });
  });
}
