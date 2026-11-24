import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';
import 'package:memora/application/usecases/shopping_list/shopping_list.dart';
import 'package:memora/composition_root/providers/shopping_list_providers.dart';
import 'package:memora/presentation/app/app_router.dart';
import 'package:memora/presentation/features/shopping_list/shopping_item_add_form.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import '../../app/top_page_test_support.dart';
import 'shopping_list_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ShoppingList>()])
void main() {
  final app = TopPageTestContext();
  setUp(app.setUpContext);

  testWidgets('所属グループ一覧で選択し、戻る操作で一覧に戻れる', (tester) async {
    final group = app.groupsWithMembers.first;
    final list = MockShoppingList();
    when(list.watchPending(group.id)).thenAnswer((_) => Stream.value([]));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...app.createTopPageTestOverrides(initialLocation: '/shopping-list'),
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

    expect(find.text('グループを選択'), findsOneWidget);
    expect(find.text('グループ2'), findsOneWidget);
    expect(find.text('${group.members.length}人のメンバー'), findsWidgets);
    await tester.tap(find.text(group.name));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, '追加'), findsOneWidget);
    expect(find.text('グループを選択'), findsNothing);
    await tester.tap(find.byTooltip('戻る'));
    await tester.pumpAndSettle();
    expect(find.text('グループを選択'), findsOneWidget);
    expect(find.text('グループ2'), findsOneWidget);

    await tester.tap(find.text(group.name));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('グループを選択'), findsOneWidget);
  });

  testWidgets('一覧の上で品物名と数量を入力して追加できる', (tester) async {
    final group = app.groupsWithMembers.first;
    const item = ShoppingListItem(
      id: 'milk',
      name: '牛乳',
      pendingQuantity: '2本',
    );
    final stream = StreamController<List<ShoppingListItem>>();
    addTearDown(stream.close);
    final list = MockShoppingList();
    when(list.watchPending(group.id)).thenAnswer((_) => stream.stream);
    when(list.add(group.id, '牛乳', '2本')).thenAnswer((_) async {
      stream.add([item]);
      return null;
    });
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final name = find.widgetWithText(TextField, '品物名');
    final quantity = find.descendant(
      of: find.byType(ShoppingItemAddForm),
      matching: find.widgetWithText(TextField, '数量'),
    );
    final add = find.widgetWithText(ElevatedButton, '追加');
    expect(tester.widget<TextField>(quantity).decoration?.hintText, isNull);
    expect(name, findsOneWidget);
    expect(add, findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    stream.add([]);
    await tester.pumpAndSettle();

    await tester.enterText(name, '牛乳');
    await tester.enterText(quantity, '2本');
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('牛乳'), findsOneWidget);
    expect(find.text('2本'), findsOneWidget);
    expect(tester.widget<TextField>(name).controller!.text, isEmpty);
    expect(tester.widget<TextField>(quantity).controller!.text, isEmpty);
    verify(list.add(group.id, '牛乳', '2本')).called(1);
  });

  testWidgets('一覧の行で品物名と数量を編集し、入力の確定でまとめて保存できる', (tester) async {
    final group = app.groupsWithMembers.first;
    const item = ShoppingListItem(
      id: 'milk',
      name: '牛乳',
      version: 1,
      pendingQuantity: '',
    );
    const edited = ShoppingListItem(
      id: 'low-fat-milk',
      name: '低脂肪乳',
      version: 1,
      pendingQuantity: '2本',
    );
    final stream = StreamController<List<ShoppingListItem>>();
    addTearDown(stream.close);
    final list = MockShoppingList();
    when(list.watchPending(group.id)).thenAnswer((_) => stream.stream);
    when(list.edit(group.id, item, edited.name, edited.pendingQuantity!))
        .thenAnswer((_) async {
          stream.add([edited]);
          return null;
        });
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
    stream.add([item]);
    await tester.pumpAndSettle();

    final row = find.ancestor(
      of: find.byType(Checkbox),
      matching: find.byType(ListTile),
    );
    final fields = find.descendant(of: row, matching: find.byType(TextField));
    expect(fields, findsNWidgets(2));
    expect(tester.widget<TextField>(fields.at(1)).decoration?.hintText, '数量');
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    await tester.enterText(fields.at(0), edited.name);
    await tester.enterText(fields.at(1), edited.pendingQuantity!);
    verifyNever(list.edit(any, any, any, any));

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    verify(list.edit(group.id, item, edited.name, edited.pendingQuantity!))
        .called(1);
    expect(find.text(edited.name), findsOneWidget);
    expect(find.text(edited.pendingQuantity!), findsOneWidget);
  });

  testWidgets('品物の削除はキャンセルでき、競合後は最新の品物を削除できる', (tester) async {
    final group = app.groupsWithMembers.first;
    const item = ShoppingListItem(
      id: 'milk',
      name: '牛乳',
      version: 1,
      pendingQuantity: '',
    );
    final stream = StreamController<List<ShoppingListItem>>();
    addTearDown(stream.close);
    final list = MockShoppingList();
    when(list.watchPending(group.id)).thenAnswer((_) => stream.stream);
    final updated = item.copyWith(version: 2, pendingQuantity: '3本');
    final deletion = Completer<void>();
    when(list.delete(group.id, item)).thenAnswer((_) => deletion.future);
    when(list.delete(group.id, updated)).thenAnswer((_) async {
      stream.add([]);
    });
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
    stream.add([item]);
    await tester.pumpAndSettle();

    final delete = find.byTooltip('削除');
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('牛乳'), findsOneWidget);
    verifyNever(list.delete(group.id, item));

    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '削除'));
    await tester.pumpAndSettle();
    stream.add([updated]);
    await tester.pumpAndSettle();
    expect(find.text('3本'), findsNothing);
    deletion.completeError(TestException('削除の競合'));
    await tester.pumpAndSettle();
    verify(list.delete(group.id, item)).called(1);
    expect(find.text('3本'), findsOneWidget);

    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '削除'));
    await tester.pumpAndSettle();
    verify(list.delete(group.id, updated)).called(1);
    expect(find.text('牛乳'), findsNothing);
  });

  testWidgets('購入履歴から数量を空欄で再登録し、履歴を確認して削除できる', (tester) async {
    final group = app.groupsWithMembers.first;
    final item = ShoppingListItem(
      id: 'milk',
      name: '牛乳',
      version: 1,
      purchasedAt: app.fixedNow,
      purchasedQuantity: '2本',
    );
    final list = MockShoppingList();
    final stream = StreamController<List<ShoppingListItem>>();
    addTearDown(stream.close);
    when(list.watchPending(group.id)).thenAnswer((_) => stream.stream);
    when(list.purchases(group.id)).thenAnswer((_) async => [item]);
    when(list.add(group.id, item.name, '')).thenAnswer((_) async {
      stream.add([item.copyWith(pendingQuantity: '')]);
      return null;
    });
    when(list.deletePurchase(group.id, item)).thenAnswer((_) async {});
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
    stream.add([]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('購入履歴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('再登録'));
    await tester.pumpAndSettle();
    verify(list.add(group.id, item.name, '')).called(1);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.text('追加履歴から選ぶ'), findsNothing);

    await tester.tap(find.text('購入履歴'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('購入履歴から削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(BottomSheet), matching: find.text('牛乳')),
      findsOneWidget,
    );
    verifyNever(list.deletePurchase(group.id, item));

    await tester.tap(find.byTooltip('購入履歴から削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '削除'));
    await tester.pumpAndSettle();
    expect(find.text('購入履歴がありません'), findsOneWidget);
    verify(list.deletePurchase(group.id, item)).called(1);
  });

  testWidgets('再登録の保存を待たず購入履歴を閉じても買い物リストに留まる', (tester) async {
    final group = app.groupsWithMembers.first;
    final item = ShoppingListItem(
      id: 'milk',
      name: '牛乳',
      purchasedAt: app.fixedNow,
      purchasedQuantity: '2本',
    );
    final save = Completer<ShoppingListItem?>();
    final list = MockShoppingList();
    when(list.watchPending(group.id)).thenAnswer((_) => Stream.value([]));
    when(list.purchases(group.id)).thenAnswer((_) async => [item]);
    when(list.add(group.id, item.name, '')).thenAnswer((_) => save.future);
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

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    await tester.tap(find.text('再登録'));
    await tester.pump();
    await tester.tap(find.byTooltip('閉じる'));
    await tester.pump();
    save.complete(null);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.widgetWithText(ElevatedButton, '追加'), findsOneWidget);
  });

  testWidgets('買い物リストから移動した後に追加結果の重複ダイアログが開かない', (tester) async {
    final group = app.groupsWithMembers.first;
    const item = ShoppingListItem(id: 'milk', name: '牛乳', pendingQuantity: '');
    final save = Completer<ShoppingListItem?>();
    final list = MockShoppingList();
    when(list.watchPending(group.id)).thenAnswer((_) => Stream.value([item]));
    when(list.add(group.id, item.name, '')).thenAnswer((_) => save.future);
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
    final addName = find.descendant(
      of: find.byType(ShoppingItemAddForm),
      matching: find.widgetWithText(TextField, '品物名'),
    );
    await tester.enterText(addName, '牛乳');
    await tester.tap(find.widgetWithText(ElevatedButton, '追加'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('hamburger_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    save.complete(item);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings')), findsOneWidget);
    expect(find.text('品物を編集'), findsNothing);
  });

  testWidgets('チェックの保存に失敗した品物は残り、再試行後は元に戻せる', (tester) async {
    final group = app.groupsWithMembers.first;
    const item = ShoppingListItem(
      id: 'milk',
      name: '牛乳',
      version: 1,
      pendingQuantity: '2本',
    );
    final checked = item.copyWith(version: 2, pendingQuantity: null);
    final stream = StreamController<List<ShoppingListItem>>();
    addTearDown(stream.close);
    final list = MockShoppingList();
    var save = Completer<ShoppingListItem>();
    when(list.watchPending(group.id)).thenAnswer((_) => stream.stream);
    when(list.check(group.id, item)).thenAnswer((_) => save.future);
    when(list.undo(group.id, item, checked)).thenAnswer((_) async {
      stream.add([item]);
    });
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
    stream.add([item]);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(find.text('牛乳'), findsOneWidget);
    save.completeError(TestException());
    await tester.pumpAndSettle();
    expect(find.text('牛乳'), findsOneWidget);
    expect(find.text('チェックを保存できませんでした。再試行してください。'), findsOneWidget);

    save = Completer<ShoppingListItem>();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    stream.add([]);
    await tester.pump();
    save.complete(checked);
    await tester.pumpAndSettle();
    expect(find.text('牛乳'), findsNothing);

    await tester.tap(find.text('元に戻す'));
    await tester.pumpAndSettle();
    expect(find.text('牛乳'), findsOneWidget);
    expect(find.text('2本'), findsOneWidget);
    verify(list.undo(group.id, item, checked)).called(1);

    await tester.tap(find.byTooltip('戻る'));
    await tester.pumpAndSettle();
    expect(find.text('グループを選択'), findsOneWidget);
    expect(find.text(group.name), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '追加'), findsNothing);
  });
}
