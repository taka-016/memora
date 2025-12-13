import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/presentation/features/trip/trip_edit_modal.dart';
import 'package:memora/presentation/shared/sheets/pin_detail_bottom_sheet.dart';

void main() {
  group('TripEditModal', () {
    testWidgets('新規作成モードでタイトルが正しく表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('旅行新規作成'), findsOneWidget);
    });

    testWidgets('編集モードでタイトルが正しく表示されること', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'test-trip-id',
        groupId: 'test-group-id',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: tripEntry,
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('旅行編集'), findsOneWidget);
    });

    testWidgets('既存旅行の情報がフォームに正しく表示されること', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'test-trip-id',
        groupId: 'test-group-id',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: tripEntry,
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 旅行名が表示されていることを確認
      expect(find.text('テスト旅行'), findsOneWidget);
      // メモが表示されていることを確認
      expect(find.text('テストメモ'), findsOneWidget);
    });

    testWidgets('旅行期間From、旅行期間Toの入力フィールドが表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('旅行期間 From'), findsOneWidget);
      expect(find.text('旅行期間 To'), findsOneWidget);
    });

    testWidgets('メモの入力フィールドが表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('メモ'), findsOneWidget);
    });

    testWidgets('編集ボタンがメモの下に表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('編集'), findsOneWidget);
    });

    testWidgets('経路情報ボタンが表示され、タップで現在のダイアログ内に経路情報ビューが表示されること', (
      WidgetTester tester,
    ) async {
      final pins = [
        const PinDto(
          pinId: 'pin-1',
          latitude: 35.0,
          longitude: 135.0,
          locationName: '京都駅',
        ),
        const PinDto(
          pinId: 'pin-2',
          latitude: 35.1,
          longitude: 135.1,
          locationName: '清水寺',
        ),
      ];

      final testHandle = TripEditModalTestHandle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
              testHandle: testHandle,
            ),
          ),
        ),
      );

      testHandle.setPinsForTest(pins);
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(ElevatedButton, '経路情報');
      expect(buttonFinder, findsOneWidget);

      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('route_info_view_root')), findsOneWidget);

      // 経路情報ビュー内の閉じるボタンで元の画面に戻れることを確認
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('route_info_view_root')),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('route_info_view_root')), findsNothing);
    });

    testWidgets('編集ボタンをタップで地図が展開表示されること', (WidgetTester tester) async {
      final testHandle = TripEditModalTestHandle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
              testHandle: testHandle,
            ),
          ),
        ),
      );

      // 初期状態では地図が表示されていないことを確認
      expect(find.byKey(const Key('map_view')), findsNothing);

      // 初期状態では編集ボタンが表示されることを確認
      expect(find.text('編集'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(IconButton),
          matching: find.byIcon(Icons.close),
        ),
        findsNothing,
      );

      // 編集ボタンを直接呼び出してテスト
      final mapSelectionButton = find.widgetWithText(ElevatedButton, '編集');
      await tester.ensureVisible(mapSelectionButton);
      await tester.tap(mapSelectionButton);
      await tester.pumpAndSettle();

      // 地図が展開表示されることを確認
      expect(find.byKey(const Key('map_view')), findsOneWidget);

      // closeアイコンが表示されることを確認
      expect(
        find.descendant(
          of: find.byType(IconButton),
          matching: find.byIcon(Icons.close),
        ),
        findsOneWidget,
      );
      // 地図展開時はアクションボタンが非表示になることを確認
      expect(find.text('キャンセル'), findsNothing);
      expect(find.text('作成'), findsNothing);
      expect(find.text('更新'), findsNothing);
    });

    testWidgets('×アイコンをタップで地図が閉じること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 編集ボタンを直接呼び出して地図を展開
      final mapSelectionButton = find.widgetWithText(ElevatedButton, '編集');
      await tester.ensureVisible(mapSelectionButton);
      await tester.tap(mapSelectionButton);
      await tester.pumpAndSettle();

      // 地図が表示されることを確認
      expect(find.byKey(const Key('map_view')), findsOneWidget);

      // closeボタンのonPressedを直接呼び出し
      final mapOutlinedButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.close),
      );
      mapOutlinedButton.onPressed!();
      await tester.pumpAndSettle();

      // 地図が閉じることを確認
      expect(find.byKey(const Key('map_view')), findsNothing);

      // 地図画面が閉じることを確認
      expect(find.text('訪問場所'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(IconButton),
          matching: find.byIcon(Icons.close),
        ),
        findsNothing,
      );

      // 地図が閉じられた後はアクションボタンが再表示されることを確認
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('作成'), findsOneWidget);
    });

    testWidgets('新規作成時は「作成」ボタンが表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('作成'), findsOneWidget);
    });

    testWidgets('編集時は「更新」ボタンが表示されること', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'test-trip-id',
        groupId: 'test-group-id',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: tripEntry,
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('更新'), findsOneWidget);
    });

    testWidgets('キャンセルボタンが表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('キャンセル'), findsOneWidget);
    });

    testWidgets('作成ボタンタップ時にonSaveコールバックが呼ばれること', (WidgetTester tester) async {
      TripEntry? savedTripEntry;

      final testHandle = TripEditModalTestHandle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (TripEntry tripEntry) {
                savedTripEntry = tripEntry;
              },
              isTestEnvironment: true,
              testHandle: testHandle,
            ),
          ),
        ),
      );

      // 旅行名を入力
      await tester.enterText(find.byType(TextFormField).first, 'テスト旅行');

      // 開始日を設定
      await tester.tap(find.text('旅行期間 From'));
      await tester.pumpAndSettle();
      // カレンダーで日付を選択（15日をタップ）
      await tester.tap(find.text('15').last);
      await tester.pumpAndSettle();

      // 終了日を設定
      await tester.tap(find.text('旅行期間 To'));
      await tester.pumpAndSettle();
      // カレンダーで日付を選択（20日をタップ）
      await tester.tap(find.text('20').last);
      await tester.pumpAndSettle();

      // 作成ボタンをタップ
      await tester.tap(find.text('作成'));
      await tester.pumpAndSettle();

      // onSaveコールバックが呼ばれ、適切なTripEntryオブジェクトが渡されることを確認
      expect(savedTripEntry, isNotNull);
      expect(savedTripEntry!.groupId, equals('test-group-id'));
      expect(savedTripEntry!.tripName, equals('テスト旅行'));
      expect(savedTripEntry!.id, equals(''));
    });

    testWidgets('更新ボタンタップ時にonSaveコールバックが呼ばれること', (WidgetTester tester) async {
      final existingTripEntry = TripEntryDto(
        id: 'existing-trip-id',
        groupId: 'test-group-id',
        tripName: '既存旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '既存メモ',
      );

      TripEntry? updatedTripEntry;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: existingTripEntry,
              onSave: (TripEntry tripEntry) {
                updatedTripEntry = tripEntry;
              },
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 旅行名を変更
      await tester.enterText(find.byType(TextFormField).first, '更新された旅行');

      // 更新ボタンをタップ
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // onSaveコールバックが呼ばれ、更新されたTripEntryオブジェクトが渡されることを確認
      expect(updatedTripEntry, isNotNull);
      expect(updatedTripEntry!.id, equals('existing-trip-id'));
      expect(updatedTripEntry!.groupId, equals('test-group-id'));
      expect(updatedTripEntry!.tripName, equals('更新された旅行'));
    });

    testWidgets('日付未入力時にエラーメッセージが表示されること', (WidgetTester tester) async {
      TripEntry? savedTripEntry;
      final testHandle = TripEditModalTestHandle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (TripEntry tripEntry) {
                savedTripEntry = tripEntry;
              },
              isTestEnvironment: true,
              testHandle: testHandle,
            ),
          ),
        ),
      );

      // 旅行名を入力
      await tester.enterText(find.byType(TextFormField).first, 'テスト旅行');

      // 作成ボタンをタップ（日付は未入力）
      await tester.tap(find.text('作成'));
      await tester.pumpAndSettle();

      // エラーメッセージが表示されることを確認
      expect(find.text('開始日と終了日を選択してください'), findsOneWidget);
      // onSaveコールバックが呼ばれないことを確認
      expect(savedTripEntry, isNull);
    });

    testWidgets('開始日が終了日より後の場合にエラーメッセージが表示されること', (WidgetTester tester) async {
      TripEntry? savedTripEntry;

      final testHandle = TripEditModalTestHandle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: TripEntryDto(
                id: 'test-id',
                groupId: 'test-group-id',
                tripName: 'テスト旅行',
                tripStartDate: DateTime(2024, 1, 1),
                tripEndDate: DateTime(2024, 1, 3),
                tripMemo: 'テストメモ',
              ),
              onSave: (TripEntry tripEntry) {
                savedTripEntry = tripEntry;
              },
              isTestEnvironment: true,
              testHandle: testHandle,
            ),
          ),
        ),
      );

      testHandle.setDateRangeForTest(
        DateTime(2024, 1, 3),
        DateTime(2024, 1, 1),
      );
      await tester.pump();

      // 更新ボタンをタップ
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // エラーメッセージが表示されることを確認
      expect(find.text('開始日は終了日より前の日付を選択してください'), findsOneWidget);
      // onSaveコールバックが呼ばれないことを確認
      expect(savedTripEntry, isNull);
    });

    testWidgets('開始日がパラメータの年と異なる場合にエラーメッセージが表示されること', (
      WidgetTester tester,
    ) async {
      TripEntry? savedTripEntry;

      final testHandle = TripEditModalTestHandle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              year: 2024,
              tripEntry: TripEntryDto(
                id: 'test-id',
                groupId: 'test-group-id',
                tripName: 'テスト旅行',
                tripStartDate: DateTime(2023, 6, 1), // 2024年以外
                tripEndDate: DateTime(2024, 6, 10),
                tripMemo: 'テストメモ',
              ),
              onSave: (TripEntry tripEntry) {
                savedTripEntry = tripEntry;
              },
              isTestEnvironment: true,
              testHandle: testHandle,
            ),
          ),
        ),
      );

      testHandle.setDateRangeForTest(
        DateTime(2023, 6, 1),
        DateTime(2024, 6, 10),
      );

      // 更新ボタンをタップ
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // エラーメッセージが表示されることを確認
      expect(find.text('開始日は2024年の日付を選択してください'), findsOneWidget);
      // onSaveコールバックが呼ばれないことを確認
      expect(savedTripEntry, isNull);
    });

    testWidgets('終了日がパラメータの年と異なる場合でも正常に保存されること（年またぎ対応）', (
      WidgetTester tester,
    ) async {
      TripEntry? savedTripEntry;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              year: 2024,
              tripEntry: TripEntryDto(
                id: 'test-id',
                groupId: 'test-group-id',
                tripName: 'テスト旅行',
                tripStartDate: DateTime(2024, 12, 30),
                tripEndDate: DateTime(2025, 1, 3), // 年またぎ
                tripMemo: 'テストメモ',
              ),
              onSave: (TripEntry tripEntry) {
                savedTripEntry = tripEntry;
              },
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 更新ボタンをタップ
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // エラーメッセージが表示されないことを確認
      expect(find.text('開始日は2024年の日付を選択してください'), findsNothing);
      // onSaveコールバックが呼ばれることを確認
      expect(savedTripEntry, isNotNull);
      expect(savedTripEntry!.tripStartDate, equals(DateTime(2024, 12, 30)));
      expect(savedTripEntry!.tripEndDate, equals(DateTime(2025, 1, 3)));
    });

    testWidgets('開始日が入力済みで終了日が未入力の場合、終了日タップ時に開始日の年月を初期値とすること', (
      WidgetTester tester,
    ) async {
      const groupId = 'test-group-id';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TripEditModal(
                  groupId: groupId,
                  onSave: (TripEntry tripEntry) {},
                  isTestEnvironment: true,
                );
              },
            ),
          ),
        ),
      );

      // 開始日を設定（2024年3月15日）
      await tester.tap(find.text('旅行期間 From'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').last);
      await tester.pumpAndSettle();

      // 開始日が設定されていることを確認
      final now = DateTime.now();
      final expectedStartDate =
          '${now.year}/${now.month.toString().padLeft(2, '0')}/15';
      expect(find.text(expectedStartDate), findsOneWidget);

      // 終了日は未選択状態であることを確認
      expect(find.text('旅行期間 To'), findsOneWidget);

      // 終了日フィールドをタップしてDatePickerを開く
      await tester.tap(find.text('旅行期間 To'));
      await tester.pumpAndSettle();

      // DatePicker(CustomDatePickerDialog)が開かれていることを確認
      expect(
        find.byType(Dialog),
        findsNWidgets(2),
      ); // TripEditModalのDialog + CustomDatePickerDialog

      // 開始日の年月（現在の年・月）に基づく初期値が表示されていることを確認
      // CustomDatePickerDialogでは選択日が「2024年8月1日 (木)」のような形式で表示される
      // 開始日が15日で、終了日の初期値は同年月の1日になる
      final expectedDisplayDate = '${now.year}年${now.month}月1日';
      expect(find.textContaining(expectedDisplayDate), findsOneWidget);

      // DatePickerを閉じる（バックドロップをタップ）
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();
    });

    testWidgets('作成ボタン押下時にonSaveコールバックでpinsが渡されること', (
      WidgetTester tester,
    ) async {
      TripEntry? savedTripEntry;
      final testHandle = TripEditModalTestHandle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (TripEntry tripEntry) {
                savedTripEntry = tripEntry;
              },
              isTestEnvironment: true,
              testHandle: testHandle,
            ),
          ),
        ),
      );

      // テスト用のピンデータをセット
      final testPins = [
        PinDto(
          pinId: 'test-pin-1',
          tripId: 'test-trip-id',
          latitude: 35.6762,
          longitude: 139.6503,
          locationName: '東京駅',
        ),
        PinDto(
          pinId: 'test-pin-2',
          tripId: 'test-trip-id',
          latitude: 35.6585,
          longitude: 139.7454,
          locationName: '渋谷駅',
        ),
      ];

      testHandle.setPinsForTest(testPins);
      await tester.pump();

      // 旅行名を入力
      await tester.enterText(find.byType(TextFormField).first, 'テスト旅行');

      // 開始日を設定
      await tester.tap(find.text('旅行期間 From'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').last);
      await tester.pumpAndSettle();

      // 終了日を設定
      await tester.tap(find.text('旅行期間 To'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20').last);
      await tester.pumpAndSettle();

      // 作成ボタンをタップ
      await tester.tap(find.text('作成'));
      await tester.pumpAndSettle();

      // onSaveコールバックでピンデータが正しく渡されることを確認
      expect(savedTripEntry, isNotNull);
      expect(savedTripEntry!.pins.length, equals(2));
      expect(savedTripEntry!.pins[0].pinId, equals('test-pin-1'));
      expect(savedTripEntry!.pins[0].locationName, equals('東京駅'));
      expect(savedTripEntry!.pins[1].pinId, equals('test-pin-2'));
      expect(savedTripEntry!.pins[1].locationName, equals('渋谷駅'));
    });

    testWidgets('ピンが存在する場合、訪問場所一覧が表示されること', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'existing-trip-id',
        groupId: 'test-group-id',
        tripName: '既存旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '既存メモ',
        pins: [
          PinDto(
            pinId: 'test-pin-1',
            tripId: 'test-trip-id',
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: '東京駅',
            visitStartDate: DateTime(2024, 1, 1, 10, 0),
            visitEndDate: DateTime(2024, 1, 1, 12, 0),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: tripEntry,
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 場所名が表示されることを確認
      expect(find.text('東京駅'), findsOneWidget);
      // 日時が表示されることを確認
      expect(find.text('01/01 10:00 - 01/01 12:00'), findsOneWidget);
    });

    testWidgets('ピンが存在しない場合、訪問場所一覧が表示されないこと', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'existing-trip-id',
        groupId: 'test-group-id',
        tripName: '既存旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '既存メモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: tripEntry,
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 場所名が表示されないことを確認
      expect(find.byKey(const Key('pinListItem_test-pin-1')), findsNothing);
    });

    testWidgets('locationNameが空の場合、空白で表示されること', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'existing-trip-id',
        groupId: 'test-group-id',
        tripName: '既存旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '既存メモ',
        pins: [
          PinDto(
            pinId: 'test-pin-1',
            tripId: 'test-trip-id',
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: null,
            visitStartDate: DateTime(2024, 1, 1, 10, 0),
            visitEndDate: DateTime(2024, 1, 1, 12, 0),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: tripEntry,
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 空白のタイトル（Text('')）があることを確認
      final emptyTextWidget = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == '',
      );
      expect(emptyTextWidget, findsOneWidget);
    });

    testWidgets('複数のピンが正しく表示されること', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'existing-trip-id',
        groupId: 'test-group-id',
        tripName: '既存旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '既存メモ',
        pins: [
          PinDto(
            pinId: 'test-pin-1',
            tripId: 'test-trip-id',
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: '東京駅',
            visitStartDate: DateTime(2024, 1, 1, 10, 0),
            visitEndDate: DateTime(2024, 1, 1, 12, 0),
          ),
          PinDto(
            pinId: 'test-pin-2',
            tripId: 'test-trip-id',
            latitude: 35.6585,
            longitude: 139.7454,
            locationName: '渋谷駅',
            visitStartDate: DateTime(2024, 1, 2, 14, 0),
            visitEndDate: DateTime(2024, 1, 2, 16, 0),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: tripEntry,
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 両方のピンが表示されることを確認
      expect(find.text('東京駅'), findsOneWidget);
      expect(find.text('渋谷駅'), findsOneWidget);
      // 日時情報も表示されることを確認
      expect(find.text('01/01 10:00 - 01/01 12:00'), findsOneWidget);
      expect(find.text('01/02 14:00 - 01/02 16:00'), findsOneWidget);
    });

    testWidgets('ピンリストをタップするとボトムシートが表示されること', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'existing-trip-id',
        groupId: 'test-group-id',
        tripName: '既存旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '既存メモ',
        pins: [
          PinDto(
            pinId: 'test-pin-1',
            tripId: 'test-trip-id',
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: '東京駅',
            visitStartDate: DateTime(2024, 1, 1, 10, 0),
            visitEndDate: DateTime(2024, 1, 1, 12, 0),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: tripEntry,
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // ピンリストアイテムを表示してからタップ
      await tester.ensureVisible(
        find.byKey(const Key('pinListItem_test-pin-1')),
      );
      await tester.tap(find.byKey(const Key('pinListItem_test-pin-1')));
      await tester.pumpAndSettle();

      // ボトムシートが表示されることを確認（PinDetailBottomSheetが表示される）
      expect(find.byType(PinDetailBottomSheet), findsOneWidget);
    });

    testWidgets('削除ボタンがピンリストアイテムに表示されること', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'existing-trip-id',
        groupId: 'test-group-id',
        tripName: '既存旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '既存メモ',
        pins: [
          PinDto(
            pinId: 'test-pin-1',
            tripId: 'test-trip-id',
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: '東京駅',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: tripEntry,
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 削除ボタンが表示されることを確認
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('削除ボタンをタップするとピンが一覧から削除されること', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'existing-trip-id',
        groupId: 'test-group-id',
        tripName: '既存旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '既存メモ',
        pins: [
          PinDto(
            pinId: 'test-pin-1',
            tripId: 'test-trip-id',
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: '東京駅',
          ),
          PinDto(
            pinId: 'test-pin-2',
            tripId: 'test-trip-id',
            latitude: 35.6585,
            longitude: 139.7454,
            locationName: '渋谷駅',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: tripEntry,
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 初期状態では両方のピンが表示されることを確認
      expect(find.text('東京駅'), findsOneWidget);
      expect(find.text('渋谷駅'), findsOneWidget);

      // 最初の削除ボタンをタップ（東京駅を削除）
      final deleteButton = find.byIcon(Icons.delete).first;
      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pump(); // setStateの反映を待つ

      // 東京駅が削除され、渋谷駅のみ表示されることを確認
      expect(find.text('東京駅'), findsNothing);
      expect(find.text('渋谷駅'), findsOneWidget);
    });

    testWidgets('全てのピンを削除すると訪問場所一覧が非表示になること', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'existing-trip-id',
        groupId: 'test-group-id',
        tripName: '既存旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '既存メモ',
        pins: [
          PinDto(
            pinId: 'test-pin-1',
            tripId: 'test-trip-id',
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: '東京駅',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: tripEntry,
              onSave: (TripEntry tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 初期状態では訪問場所一覧が表示されることを確認
      expect(find.text('東京駅'), findsOneWidget);

      // 削除ボタンをタップ
      final deleteButton = find.byIcon(Icons.delete);
      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pump(); // setStateの反映を待つ

      // 訪問場所一覧が非表示になることを確認
      expect(find.text('東京駅'), findsNothing);
    });
  });
}
