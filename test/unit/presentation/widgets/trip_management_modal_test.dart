import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/presentation/widgets/trip_management_modal.dart';

void main() {
  group('TripManagementModal', () {
    testWidgets('新規作成時にタイトルが正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TripManagementModal(
            groupId: 'test-group-id',
            onSave: (tripEntry) {},
          ),
        ),
      );

      expect(find.text('旅行新規作成'), findsOneWidget);
    });

    testWidgets('編集時にタイトルが正しく表示される', (WidgetTester tester) async {
      final tripEntry = TripEntry(
        id: 'test-id',
        groupId: 'test-group-id',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TripManagementModal(
            groupId: 'test-group-id',
            tripEntry: tripEntry,
            onSave: (tripEntry) {},
          ),
        ),
      );

      expect(find.text('旅行編集'), findsOneWidget);
    });

    testWidgets('必須フィールドが空の場合にバリデーションエラーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TripManagementModal(
            groupId: 'test-group-id',
            onSave: (tripEntry) {},
          ),
        ),
      );

      // 作成ボタンをタップ
      await tester.tap(find.text('作成'));
      await tester.pump();

      expect(find.text('開始日を入力してください'), findsOneWidget);
      expect(find.text('終了日を入力してください'), findsOneWidget);
    });

    testWidgets('有効な入力でonSaveコールバックが呼ばれる', (WidgetTester tester) async {
      TripEntry? savedTripEntry;

      await tester.pumpWidget(
        MaterialApp(
          home: TripManagementModal(
            groupId: 'test-group-id',
            onSave: (tripEntry) {
              savedTripEntry = tripEntry;
            },
          ),
        ),
      );

      // 旅行名を入力
      await tester.enterText(find.byKey(const Key('trip_name_field')), 'テスト旅行');
      await tester.pump();

      // 開始日を設定
      await tester.tap(find.byKey(const Key('start_date_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 終了日を設定
      await tester.tap(find.byKey(const Key('end_date_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 作成ボタンをタップ
      await tester.tap(find.text('作成'));
      await tester.pump();

      expect(savedTripEntry, isNotNull);
      expect(savedTripEntry!.tripName, 'テスト旅行');
      expect(savedTripEntry!.groupId, 'test-group-id');
    });

    testWidgets('編集時に既存データが正しく表示される', (WidgetTester tester) async {
      final tripEntry = TripEntry(
        id: 'test-id',
        groupId: 'test-group-id',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TripManagementModal(
            groupId: 'test-group-id',
            tripEntry: tripEntry,
            onSave: (tripEntry) {},
          ),
        ),
      );

      // 既存データが表示されることを確認
      expect(find.text('テスト旅行'), findsOneWidget);
      expect(find.text('テストメモ'), findsOneWidget);
      expect(find.text('更新'), findsOneWidget);
    });

    testWidgets('キャンセルボタンでダイアログが閉じる', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => TripManagementModal(
                    groupId: 'test-group-id',
                    onSave: (tripEntry) {},
                  ),
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // モーダルを開く
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // モーダルが表示されることを確認
      expect(find.text('旅行新規作成'), findsOneWidget);

      // キャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // モーダルが閉じることを確認
      expect(find.text('旅行新規作成'), findsNothing);
    });

    testWidgets('フォームの各入力項目が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TripManagementModal(
            groupId: 'test-group-id',
            onSave: (tripEntry) {},
          ),
        ),
      );

      // 各フィールドが表示されることを確認
      expect(find.byKey(const Key('trip_name_field')), findsOneWidget);
      expect(find.byKey(const Key('start_date_field')), findsOneWidget);
      expect(find.byKey(const Key('end_date_field')), findsOneWidget);
      expect(find.byKey(const Key('trip_memo_field')), findsOneWidget);
    });

    testWidgets('日付の範囲バリデーションが機能する', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TripManagementModal(
            groupId: 'test-group-id',
            onSave: (tripEntry) {},
          ),
        ),
      );

      // 終了日が開始日より前の場合のバリデーションをテスト
      // 実装時に詳細なテストケースを追加予定
      expect(find.byKey(const Key('start_date_field')), findsOneWidget);
      expect(find.byKey(const Key('end_date_field')), findsOneWidget);
    });
  });
}
