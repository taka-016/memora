import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/widgets/pin_detail_bottom_sheet.dart';
import 'package:memora/domain/entities/pin.dart';

void main() {
  group('PinDetailBottomSheet', () {
    testWidgets('PinDetailBottomSheetが正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      expect(find.byType(PinDetailBottomSheet), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('詳細入力画面のUI要素が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      // テキストラベルの確認
      expect(find.text('訪問開始日'), findsOneWidget);
      expect(find.text('訪問終了日'), findsOneWidget);
      expect(find.text('メモ'), findsOneWidget);

      // 入力フィールドの確認
      expect(find.byKey(const Key('visitStartDateField')), findsOneWidget);
      expect(find.byKey(const Key('visitStartTimeField')), findsOneWidget);
      expect(find.byKey(const Key('visitEndDateField')), findsOneWidget);
      expect(find.byKey(const Key('visitEndTimeField')), findsOneWidget);
      expect(find.byKey(const Key('visitMemoField')), findsOneWidget);

      // ボタンの確認
      expect(find.text('削除'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);

      // 閉じるボタンの確認
      expect(find.byIcon(Icons.close), findsOneWidget);

      // ドラッグハンドルの確認
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('日付・時間フィールドが縦並びで表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      // 日付・時間フィールドがInkWellでラップされている（4つのフィールド）
      expect(find.byType(InkWell), findsAtLeastNWidgets(4));

      // 日付・時間フィールドがOutlineBorderのContainerで表示される
      final dateContainers = find.descendant(
        of: find.byType(InkWell),
        matching: find.byType(Container),
      );
      expect(dateContainers, findsAtLeastNWidgets(4));

      // 日付選択のプレースホルダーテキストが表示される
      expect(find.text('日付を選択'), findsNWidgets(2));

      // 時間選択のプレースホルダーテキストが表示される
      expect(find.text('時間を選択'), findsNWidgets(2));

      // カレンダーアイコンが表示される
      expect(find.byIcon(Icons.calendar_today), findsNWidgets(2));

      // 時計アイコンが表示される
      expect(find.byIcon(Icons.access_time), findsNWidgets(2));
    });

    testWidgets('訪問開始日の日付選択タップでCustomDatePickerDialogが表示される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      // 開始日の日付フィールドをタップ
      await tester.tap(find.byKey(const Key('visitStartDateField')));
      await tester.pumpAndSettle();

      // CustomDatePickerDialogが表示されることを確認
      expect(find.text('日付を選択'), findsWidgets);
    });

    testWidgets('訪問開始日の時間選択タップでTimePickerが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      // 開始時間の時間フィールドが画面内に表示されるようにスクロール
      await tester.ensureVisible(find.byKey(const Key('visitStartTimeField')));
      await tester.pumpAndSettle();

      // 開始時間の時間フィールドをタップ
      await tester.tap(find.byKey(const Key('visitStartTimeField')));
      await tester.pumpAndSettle();

      // TimePicker関連のUI要素が表示されることを確認
      expect(find.text('時間を選択'), findsWidgets);
    });

    testWidgets('訪問終了日の日付選択タップでCustomDatePickerDialogが表示される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      // 終了日の日付フィールドが画面内に表示されるようにスクロール
      await tester.ensureVisible(find.byKey(const Key('visitEndDateField')));
      await tester.pumpAndSettle();

      // 終了日の日付フィールドをタップ
      await tester.tap(find.byKey(const Key('visitEndDateField')));
      await tester.pumpAndSettle();

      // CustomDatePickerDialogが表示されることを確認
      expect(find.text('日付を選択'), findsWidgets);
    });

    testWidgets('訪問終了日の時間選択タップでTimePickerが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      // 終了時間の時間フィールドが画面内に表示されるようにスクロール
      await tester.ensureVisible(find.byKey(const Key('visitEndTimeField')));
      await tester.pumpAndSettle();

      // 終了時間の時間フィールドをタップ
      await tester.tap(find.byKey(const Key('visitEndTimeField')));
      await tester.pumpAndSettle();

      // TimePicker関連のUI要素が表示されることを確認
      expect(find.text('時間を選択'), findsWidgets);
    });

    testWidgets('保存ボタンタップ時にonSaveコールバックが呼ばれること', (WidgetTester tester) async {
      bool onSaveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(
              onSave: (Pin pin) {
                onSaveCalled = true;
              },
            ),
          ),
        ),
      );

      // 保存ボタンが画面内に表示されるようにスクロール
      await tester.ensureVisible(find.text('保存'));
      await tester.pumpAndSettle();

      // 保存ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // onSaveコールバックが呼ばれたことを確認
      expect(onSaveCalled, isTrue);
    });

    testWidgets('Pinデータを受け取って初期値が正しくセットされること', (WidgetTester tester) async {
      final pin = Pin(
        id: 'test-id',
        pinId: 'test-pin-id',
        latitude: 35.681236,
        longitude: 139.767125,
        visitStartDate: DateTime(2025, 1, 15, 10, 30),
        visitEndDate: DateTime(2025, 1, 15, 15, 45),
        visitMemo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PinDetailBottomSheet(pin: pin)),
        ),
      );

      // 開始日が初期セットされていることを確認（2個の2025/01/15が見つかることを期待）
      expect(find.text('2025/01/15'), findsNWidgets(2));
      expect(find.text('10:30'), findsOneWidget);

      // 終了日が初期セットされていることを確認
      expect(find.text('15:45'), findsOneWidget);

      // メモが初期セットされていることを確認
      final memoField = find.byKey(const Key('visitMemoField'));
      expect(memoField, findsOneWidget);
      final textField = tester.widget<TextFormField>(memoField);
      expect(textField.controller?.text, equals('テストメモ'));
    });

    testWidgets('Pinデータがnullの場合は空の状態で表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet(pin: null))),
      );

      // プレースホルダーテキストが表示されることを確認
      expect(find.text('日付を選択'), findsNWidgets(2));
      expect(find.text('時間を選択'), findsNWidgets(2));

      // メモフィールドが空であることを確認
      final memoField = find.byKey(const Key('visitMemoField'));
      expect(memoField, findsOneWidget);
      final textField = tester.widget<TextFormField>(memoField);
      expect(textField.controller?.text, equals(''));
    });

    testWidgets('保存ボタンタップ時にPinデータを作成してコールバックすること', (WidgetTester tester) async {
      Pin? callbackPin;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(
              onSave: (pin) {
                callbackPin = pin;
              },
            ),
          ),
        ),
      );

      // メモを入力
      await tester.ensureVisible(find.byKey(const Key('visitMemoField')));
      await tester.enterText(find.byKey(const Key('visitMemoField')), 'テストメモ');

      // 保存ボタンをタップ
      await tester.ensureVisible(find.text('保存'));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Pinデータがコールバックされることを確認
      expect(callbackPin, isNotNull);
      expect(callbackPin!.visitMemo, equals('テストメモ'));
    });

    testWidgets('訪問開始日時が訪問終了日時より後の場合にエラーメッセージが表示されること', (
      WidgetTester tester,
    ) async {
      Pin? callbackPin;

      // 既存のPinデータを設定（開始日時 > 終了日時）
      final invalidPin = Pin(
        id: 'test-id',
        pinId: 'test-pin-id',
        latitude: 35.681236,
        longitude: 139.767125,
        visitStartDate: DateTime(2025, 1, 15, 16, 0), // 後の時間
        visitEndDate: DateTime(2025, 1, 15, 10, 0), // 前の時間
        visitMemo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(
              pin: invalidPin,
              onSave: (pin) {
                callbackPin = pin;
              },
            ),
          ),
        ),
      );

      // 保存ボタンをタップ
      await tester.ensureVisible(find.text('保存'));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // エラーメッセージが表示されることを確認
      expect(find.text('訪問開始日時は訪問終了日時より前の日時を選択してください'), findsOneWidget);

      // コールバックが呼ばれないことを確認
      expect(callbackPin, isNull);
    });

    testWidgets('訪問開始日時が訪問終了日時より前の場合は正常に保存されること', (WidgetTester tester) async {
      Pin? callbackPin;

      // 既存のPinデータを設定（開始日時 < 終了日時）
      final validPin = Pin(
        id: 'test-id',
        pinId: 'test-pin-id',
        latitude: 35.681236,
        longitude: 139.767125,
        visitStartDate: DateTime(2025, 1, 15, 10, 0), // 前の時間
        visitEndDate: DateTime(2025, 1, 15, 16, 0), // 後の時間
        visitMemo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(
              pin: validPin,
              onSave: (pin) {
                callbackPin = pin;
              },
            ),
          ),
        ),
      );

      // 保存ボタンをタップ
      await tester.ensureVisible(find.text('保存'));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // エラーメッセージが表示されないことを確認
      expect(find.text('訪問開始日時は訪問終了日時より前の日時を選択してください'), findsNothing);

      // コールバックが呼ばれることを確認
      expect(callbackPin, isNotNull);
      expect(callbackPin!.visitStartDate, equals(DateTime(2025, 1, 15, 10, 0)));
      expect(callbackPin!.visitEndDate, equals(DateTime(2025, 1, 15, 16, 0)));
    });

    testWidgets('エラーメッセージが表示された状態でもUI要素が正常に動作すること', (
      WidgetTester tester,
    ) async {
      Pin? callbackPin;

      // 無効な日時を持つPinデータ
      final invalidPin = Pin(
        id: 'test-id',
        pinId: 'test-pin-id',
        latitude: 35.681236,
        longitude: 139.767125,
        visitStartDate: DateTime(2025, 1, 15, 16, 0), // 後の時間
        visitEndDate: DateTime(2025, 1, 15, 10, 0), // 前の時間
        visitMemo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(
              pin: invalidPin,
              onSave: (pin) {
                callbackPin = pin;
              },
            ),
          ),
        ),
      );

      // 保存ボタンをタップしてエラーを表示
      await tester.ensureVisible(find.text('保存'));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // エラーメッセージが表示されることを確認
      expect(find.text('訪問開始日時は訪問終了日時より前の日時を選択してください'), findsOneWidget);

      // エラー表示後でもフィールドが存在することを確認
      expect(find.byKey(const Key('visitStartDateField')), findsOneWidget);
      expect(find.byKey(const Key('visitEndDateField')), findsOneWidget);
      expect(find.byKey(const Key('visitMemoField')), findsOneWidget);

      // エラー表示後でも保存ボタンが存在することを確認
      expect(find.text('保存'), findsOneWidget);
    });
  });
}
