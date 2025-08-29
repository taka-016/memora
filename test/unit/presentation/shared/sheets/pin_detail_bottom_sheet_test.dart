import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/presentation/shared/sheets/pin_detail_bottom_sheet.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/services/nearby_location_service.dart';

import 'pin_detail_bottom_sheet_test.mocks.dart';

@GenerateMocks([NearbyLocationService])
void main() {
  group('PinDetailBottomSheet', () {
    // デフォルトのPinオブジェクト
    final defaultPin = Pin(
      id: 'default-id',
      pinId: 'default-pin-id',
      latitude: 35.681236,
      longitude: 139.767125,
    );

    testWidgets('PinDetailBottomSheetが正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(pin: defaultPin, onClose: () {}),
          ),
        ),
      );

      expect(find.byType(PinDetailBottomSheet), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('詳細入力画面のUI要素が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(pin: defaultPin, onClose: () {}),
          ),
        ),
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

      // 場所名の確認
      expect(find.byKey(const Key('locationNameField')), findsOneWidget);

      // ボタンの確認
      expect(find.text('削除'), findsOneWidget);
      expect(find.text('更新'), findsOneWidget);

      // 閉じるボタンの確認
      expect(find.byIcon(Icons.close), findsOneWidget);

      // ドラッグハンドルの確認
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('日付・時間フィールドが縦並びで表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(pin: defaultPin, onClose: () {}),
          ),
        ),
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
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(pin: defaultPin, onClose: () {}),
          ),
        ),
      );

      // 開始日の日付フィールドが画面内に表示されるようにスクロール
      await tester.ensureVisible(find.byKey(const Key('visitStartDateField')));
      await tester.pumpAndSettle();

      // 開始日の日付フィールドをタップ
      await tester.tap(find.byKey(const Key('visitStartDateField')));
      await tester.pumpAndSettle();

      // CustomDatePickerDialogが表示されることを確認
      expect(find.text('日付を選択'), findsWidgets);
    });

    testWidgets('訪問開始日の時間選択タップでTimePickerが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(pin: defaultPin, onClose: () {}),
          ),
        ),
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
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(pin: defaultPin, onClose: () {}),
          ),
        ),
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
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(pin: defaultPin, onClose: () {}),
          ),
        ),
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

    testWidgets('更新ボタンタップ時にonUpdateコールバックが呼ばれること', (WidgetTester tester) async {
      final pin = Pin(
        id: 'test-id',
        pinId: 'test-pin-id',
        latitude: 35.681236,
        longitude: 139.767125,
        visitStartDate: DateTime(2025, 1, 15, 10, 30),
        visitEndDate: DateTime(2025, 1, 15, 15, 45),
        visitMemo: 'テストメモ',
      );

      bool onUpdateCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(
              pin: pin,
              onClose: () {},
              onUpdate: (Pin pin) {
                onUpdateCalled = true;
              },
            ),
          ),
        ),
      );

      // 更新ボタンが画面内に表示されるようにスクロール
      await tester.ensureVisible(find.text('更新'));
      await tester.pumpAndSettle();

      // 更新ボタンをタップ
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // onUpdateコールバックが呼ばれたことを確認
      expect(onUpdateCalled, isTrue);
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
          home: Scaffold(
            body: PinDetailBottomSheet(pin: pin, onClose: () {}),
          ),
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

    testWidgets('Pinデータにvisitデータがない場合は空の状態で表示されること', (
      WidgetTester tester,
    ) async {
      final emptyPin = Pin(
        id: 'empty-id',
        pinId: 'empty-pin-id',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(pin: emptyPin, onClose: () {}),
          ),
        ),
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

    testWidgets('更新ボタンタップ時にPinデータを作成してコールバックすること', (WidgetTester tester) async {
      final pin = Pin(
        id: 'test-id',
        pinId: 'test-pin-id',
        latitude: 35.681236,
        longitude: 139.767125,
        visitStartDate: DateTime(2025, 1, 15, 10, 30),
        visitEndDate: DateTime(2025, 1, 15, 15, 45),
        visitMemo: 'テストメモ',
      );

      Pin? callbackPin;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(
              pin: pin,
              onClose: () {},
              onUpdate: (pin) {
                callbackPin = pin;
              },
            ),
          ),
        ),
      );

      // メモを入力
      await tester.ensureVisible(find.byKey(const Key('visitMemoField')));
      await tester.enterText(find.byKey(const Key('visitMemoField')), 'テストメモ');

      // 更新ボタンをタップ
      await tester.ensureVisible(find.text('更新'));
      await tester.tap(find.text('更新'));
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
              onClose: () {},
              onUpdate: (pin) {
                callbackPin = pin;
              },
            ),
          ),
        ),
      );

      // 更新ボタンをタップ
      await tester.ensureVisible(find.text('更新'));
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // エラーメッセージが表示されることを確認
      expect(find.text('訪問開始日時は訪問終了日時より前の日時を選択してください'), findsOneWidget);

      // コールバックが呼ばれないことを確認
      expect(callbackPin, isNull);
    });

    testWidgets('訪問開始日時が訪問終了日時より前の場合は正常に更新されること', (WidgetTester tester) async {
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
              onClose: () {},
              onUpdate: (pin) {
                callbackPin = pin;
              },
            ),
          ),
        ),
      );

      // 更新ボタンをタップ
      await tester.ensureVisible(find.text('更新'));
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // エラーメッセージが表示されないことを確認
      expect(find.text('訪問開始日時は訪問終了日時より前の日時を選択してください'), findsNothing);

      // コールバックが呼ばれることを確認
      expect(callbackPin, isNotNull);
      expect(callbackPin!.visitStartDate, equals(DateTime(2025, 1, 15, 10, 0)));
      expect(callbackPin!.visitEndDate, equals(DateTime(2025, 1, 15, 16, 0)));
    });

    testWidgets('場所名がブランクの場合のみGoogle Places APIで場所名を取得する', (
      WidgetTester tester,
    ) async {
      final mockNearbyLocationService = MockNearbyLocationService();

      // 場所名がnullのPin
      final pinWithoutLocationName = Pin(
        id: 'test-id',
        pinId: 'test-pin-id',
        latitude: 35.681236,
        longitude: 139.767125,
        locationName: null,
      );

      // モックの設定: getLocationNameが呼ばれたら場所名を返す
      when(
        mockNearbyLocationService.getLocationName(any),
      ).thenAnswer((_) async => '取得した場所名');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(
              pin: pinWithoutLocationName,
              onClose: () {},
              reverseGeocodingService: mockNearbyLocationService,
            ),
          ),
        ),
      );

      // 非同期処理の完了を待つ
      await tester.pumpAndSettle();

      // 位置取得処理が呼ばれたことを検証
      verify(mockNearbyLocationService.getLocationName(any)).called(1);

      // 取得した場所名が表示されることを確認
      expect(find.text('取得した場所名'), findsOneWidget);
    });

    testWidgets('場所名が既にある場合はGoogle Places APIを呼び出さない', (
      WidgetTester tester,
    ) async {
      final mockNearbyLocationService = MockNearbyLocationService();

      // 場所名が既にあるPin
      final pinWithLocationName = Pin(
        id: 'test-id',
        pinId: 'test-pin-id',
        latitude: 35.681236,
        longitude: 139.767125,
        locationName: '東京駅',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(
              pin: pinWithLocationName,
              onClose: () {},
              reverseGeocodingService: mockNearbyLocationService,
            ),
          ),
        ),
      );

      // 非同期処理の完了を待つ
      await tester.pumpAndSettle();

      // 位置取得処理が呼ばれていないことを検証
      verifyNever(mockNearbyLocationService.getLocationName(any));

      // 既存の場所名が表示されることを確認
      expect(find.text('東京駅'), findsOneWidget);
    });

    testWidgets('場所名のボックス右端に更新アイコンが表示される', (WidgetTester tester) async {
      final pinWithLocationName = Pin(
        id: 'test-id',
        pinId: 'test-pin-id',
        latitude: 35.681236,
        longitude: 139.767125,
        locationName: '東京駅',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(
              pin: pinWithLocationName,
              onClose: () {},
            ),
          ),
        ),
      );

      // 更新アイコンが表示される
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('更新アイコンをタップすると位置取得処理が呼ばれる', (WidgetTester tester) async {
      final mockNearbyLocationService = MockNearbyLocationService();
      final pinWithLocationName = Pin(
        id: 'test-id',
        pinId: 'test-pin-id',
        latitude: 35.681236,
        longitude: 139.767125,
        locationName: '東京駅',
      );

      // モックの設定: getLocationNameが呼ばれたら'新しい場所名'を返す
      when(
        mockNearbyLocationService.getLocationName(any),
      ).thenAnswer((_) async => '新しい場所名');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(
              pin: pinWithLocationName,
              onClose: () {},
              reverseGeocodingService: mockNearbyLocationService,
            ),
          ),
        ),
      );

      // 初期状態では既存の場所名が表示されている
      expect(find.text('東京駅'), findsOneWidget);

      // 更新アイコンをタップ
      final refreshIconFinder = find.byIcon(Icons.refresh);
      await tester.tap(refreshIconFinder);
      await tester.pump();

      // 位置取得処理が呼ばれることを検証
      verify(mockNearbyLocationService.getLocationName(any)).called(1);

      // ローディング状態の確認
      await tester.pump();
      expect(find.text('新しい場所名'), findsOneWidget);
    });

    testWidgets('更新ボタンタップ時に取得した場所名もPinに含まれる', (WidgetTester tester) async {
      Pin? callbackPin;

      // 既に場所名があるPinで、場所名が保存されることを確認
      final pin = Pin(
        id: 'test-id',
        pinId: 'test-pin-id',
        latitude: 35.681236,
        longitude: 139.767125,
        locationName: '東京駅', // 場所名が既にある
        visitStartDate: DateTime(2025, 1, 15, 10, 30),
        visitEndDate: DateTime(2025, 1, 15, 15, 45),
        visitMemo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(
              pin: pin,
              onClose: () {},
              onUpdate: (pin) {
                callbackPin = pin;
              },
            ),
          ),
        ),
      );

      // 更新ボタンをタップ
      await tester.ensureVisible(find.text('更新'));
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // Pinデータがコールバックされることを確認
      expect(callbackPin, isNotNull);
      // 場所名がPinに含まれることを確認
      expect(callbackPin!.locationName, equals('東京駅'));
    });
  });
}
