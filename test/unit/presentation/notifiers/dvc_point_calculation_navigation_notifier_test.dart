import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/notifiers/dvc_point_calculation_navigation_notifier.dart';

void main() {
  group('DvcPointCalculationNavigationNotifier', () {
    late ProviderContainer container;
    late GroupDto testGroup;

    setUp(() {
      container = ProviderContainer();
      testGroup = const GroupDto(
        id: 'g1',
        ownerId: 'o1',
        name: 'テストグループ',
        members: [],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態でグループ一覧画面が選択されている', () {
      // Act
      final state = container.read(
        dvcPointCalculationNavigationNotifierProvider,
      );

      // Assert
      expect(state.currentScreen, DvcPointCalculationScreenState.groupList);
      expect(state.selectedGroup, isNull);
    });

    test('計算画面に遷移できる', () {
      // Arrange
      final notifier = container.read(
        dvcPointCalculationNavigationNotifierProvider.notifier,
      );

      // Act
      notifier.showCalculation(testGroup);

      // Assert
      final state = container.read(
        dvcPointCalculationNavigationNotifierProvider,
      );
      expect(state.currentScreen, DvcPointCalculationScreenState.calculation);
      expect(state.selectedGroup, testGroup);
    });

    test('グループ一覧に戻れる', () {
      // Arrange
      final notifier = container.read(
        dvcPointCalculationNavigationNotifierProvider.notifier,
      );
      notifier.showCalculation(testGroup);

      // Act
      notifier.showGroupList();

      // Assert
      final state = container.read(
        dvcPointCalculationNavigationNotifierProvider,
      );
      expect(state.currentScreen, DvcPointCalculationScreenState.groupList);
      expect(state.selectedGroup, isNull);
    });

    test('スタックインデックスを正しく取得できる', () {
      // Arrange
      final notifier = container.read(
        dvcPointCalculationNavigationNotifierProvider.notifier,
      );

      // Act / Assert
      expect(notifier.getStackIndex(), 0);
      notifier.showCalculation(testGroup);
      expect(notifier.getStackIndex(), 1);
    });
  });
}
