import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/notifiers/group_timeline_destination.dart';
import 'package:memora/presentation/notifiers/group_timeline_navigation_notifier.dart';

void main() {
  group('GroupTimelineNavigationNotifier', () {
    late ProviderContainer container;
    late GroupTimelineNavigationNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態ではグループ一覧を遷移先として保持する', () {
      expect(
        container.read(groupTimelineNavigationNotifierProvider).destination,
        const GroupTimelineGroupListDestination(),
      );
    });

    test('選択したグループIDを持つ年表へ遷移する', () {
      notifier.showGroupTimeline('group-1');

      expect(
        container.read(groupTimelineNavigationNotifierProvider).destination,
        const GroupTimelineOverviewDestination(groupId: 'group-1'),
      );
    });

    test('旅行管理から同じグループの年表へ戻る', () {
      notifier.showTripManagement('group-1', 2024, initialTripId: 'trip-1');

      expect(notifier.handleBackNavigation(), isTrue);
      expect(
        container.read(groupTimelineNavigationNotifierProvider).destination,
        const GroupTimelineOverviewDestination(groupId: 'group-1'),
      );
    });

    test('DVCポイント計算から同じグループの年表へ戻る', () {
      notifier.showDvcPointCalculation('group-1');

      expect(notifier.handleBackNavigation(), isTrue);
      expect(
        container.read(groupTimelineNavigationNotifierProvider).destination,
        const GroupTimelineOverviewDestination(groupId: 'group-1'),
      );
    });

    test('年表からグループ一覧へ戻る', () {
      notifier.showGroupTimeline('group-1');

      expect(notifier.handleBackNavigation(), isTrue);
      expect(
        container.read(groupTimelineNavigationNotifierProvider).destination,
        const GroupTimelineGroupListDestination(),
      );
    });

    test('グループ一覧では戻る操作を処理しない', () {
      expect(notifier.handleBackNavigation(), isFalse);
    });

    test('遷移先の種類からスタックインデックスを決定する', () {
      expect(notifier.getStackIndex(), 0);

      notifier.showGroupTimeline('group-1');
      expect(notifier.getStackIndex(), 1);

      notifier.showTripManagement('group-1', 2024);
      expect(notifier.getStackIndex(), 2);

      notifier.showDvcPointCalculation('group-1');
      expect(notifier.getStackIndex(), 3);
    });
  });
}
