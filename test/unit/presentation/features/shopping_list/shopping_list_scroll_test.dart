import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';
import 'package:memora/composition_root/providers/shopping_list_providers.dart';
import 'package:memora/presentation/app/app_router.dart';
import 'package:mockito/mockito.dart';

import '../../app/top_page_test_support.dart';
import 'shopping_list_screen_test.mocks.dart';

void main() {
  final app = TopPageTestContext();
  setUp(app.setUpContext);

  final verticalScroll = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );

  Future<void> openShoppingList(
    WidgetTester tester, {
    Size size = const Size(360, 640),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final group = app.groupsWithMembers.first;
    final items = List.generate(
      20,
      (index) => ShoppingListItem(
        id: 'item-$index',
        name: '品物$index',
        pendingQuantity: '',
        purchasedAt: app.fixedNow,
        purchasedQuantity: '',
      ),
    );
    final list = MockShoppingList();
    when(list.watchPending(group.id)).thenAnswer((_) => Stream.value(items));
    when(list.purchases(group.id)).thenAnswer((_) async => items);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...app.createTopPageTestOverrides(
            initialLocation: '/shopping-list',
            availableGroupsWithMembers: [group],
          ),
          shoppingListProvider.overrideWithValue(list),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(appRouterConfigProvider),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('品物の一覧をスクロールしても追加フォームと履歴の入口は固定される', (tester) async {
    await openShoppingList(tester);
    final add = find.widgetWithText(ElevatedButton, '追加');
    final history = find.text('購入済み履歴');
    final addPosition = tester.getTopLeft(add);
    final historyPosition = tester.getTopLeft(history);

    await tester.drag(verticalScroll, const Offset(0, -440));
    await tester.pumpAndSettle();

    expect(
      tester.state<ScrollableState>(verticalScroll).position.pixels,
      greaterThan(0),
    );
    expect(add.hitTestable(), findsOneWidget);
    expect(history.hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(add), addPosition);
    expect(tester.getTopLeft(history), historyPosition);
  });

  testWidgets('小さい画面でキーボードを開いても追加フォームを操作できる', (tester) async {
    await openShoppingList(tester, size: const Size(320, 480));
    final add = find.widgetWithText(ElevatedButton, '追加');
    await tester.tap(find.widgetWithText(TextField, '品物名').first);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(add.hitTestable(), findsOneWidget);
  });

  testWidgets('購入済み履歴は指定の高さで一覧だけスクロールできる', (tester) async {
    await openShoppingList(tester);
    await tester.tap(find.text('購入済み履歴'));
    await tester.pumpAndSettle();

    final modal = find.byType(BottomSheet);
    final scroll = find.descendant(of: modal, matching: verticalScroll);
    final heading = find.descendant(of: modal, matching: find.text('購入済み履歴'));
    final headingPosition = tester.getTopLeft(heading);
    final historyHeight = tester.getBottomLeft(scroll).dy - headingPosition.dy;
    expect(historyHeight, greaterThan(640 * 0.6));

    await tester.drag(scroll, const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(
      tester.state<ScrollableState>(scroll).position.pixels,
      greaterThan(0),
    );
    expect(tester.getTopLeft(heading), headingPosition);
  });
}
