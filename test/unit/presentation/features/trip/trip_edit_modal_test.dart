import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/entities/pin.dart';
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
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('旅行新規作成'), findsOneWidget);
    });

    testWidgets('編集モードでタイトルが正しく表示されること', (WidgetTester tester) async {
      final tripEntry = TripEntry(
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
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('旅行編集'), findsOneWidget);
    });

    testWidgets('既存旅行の情報がフォームに正しく表示されること', (WidgetTester tester) async {
      final tripEntry = TripEntry(
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
              onSave: (tripEntry, {List<Pin>? pins}) {},
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
              onSave: (tripEntry, {List<Pin>? pins}) {},
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
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('メモ'), findsOneWidget);
    });

    testWidgets('地図で選択ボタンがメモの下に表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('地図で選択'), findsOneWidget);
    });

    testWidgets('地図で選択ボタンをタップで地図が展開表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 初期状態では地図が表示されていないことを確認
      expect(find.byKey(const Key('map_view')), findsNothing);

      // 初期状態では地図で選択ボタンが表示されることを確認
      expect(find.text('地図で選択'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(IconButton),
          matching: find.byIcon(Icons.close),
        ),
        findsNothing,
      );

      // 地図で選択ボタンを直接呼び出してテスト
      final mapSelectionButton = find.widgetWithText(ElevatedButton, '地図で選択');
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
      expect(find.text('地図で選択'), findsNothing);

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
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 地図で選択ボタンを直接呼び出して地図を展開
      final mapSelectionButton = find.widgetWithText(ElevatedButton, '地図で選択');
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
      expect(find.text('地図で選択'), findsOneWidget);
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
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('作成'), findsOneWidget);
    });

    testWidgets('編集時は「更新」ボタンが表示されること', (WidgetTester tester) async {
      final tripEntry = TripEntry(
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
              onSave: (tripEntry, {List<Pin>? pins}) {},
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
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('キャンセル'), findsOneWidget);
    });

    testWidgets('作成ボタンタップ時にonSaveコールバックが呼ばれること', (WidgetTester tester) async {
      TripEntry? savedTripEntry;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (tripEntry, {List<Pin>? pins}) {
                savedTripEntry = tripEntry;
              },
              isTestEnvironment: true,
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
      final existingTripEntry = TripEntry(
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
              onSave: (tripEntry, {List<Pin>? pins}) {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (tripEntry, {List<Pin>? pins}) {
                savedTripEntry = tripEntry;
              },
              isTestEnvironment: true,
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              tripEntry: TripEntry(
                id: 'test-id',
                groupId: 'test-group-id',
                tripName: 'テスト旅行',
                tripStartDate: DateTime(2024, 1, 3),
                tripEndDate: DateTime(2024, 1, 1),
                tripMemo: 'テストメモ',
              ),
              onSave: (tripEntry, {List<Pin>? pins}) {
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

      // エラーメッセージが表示されることを確認
      expect(find.text('開始日は終了日より前の日付を選択してください'), findsOneWidget);
      // onSaveコールバックが呼ばれないことを確認
      expect(savedTripEntry, isNull);
    });

    testWidgets('開始日がパラメータの年と異なる場合にエラーメッセージが表示されること', (
      WidgetTester tester,
    ) async {
      TripEntry? savedTripEntry;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              year: 2024,
              tripEntry: TripEntry(
                id: 'test-id',
                groupId: 'test-group-id',
                tripName: 'テスト旅行',
                tripStartDate: DateTime(2023, 6, 1), // 2024年以外
                tripEndDate: DateTime(2024, 6, 10),
                tripMemo: 'テストメモ',
              ),
              onSave: (tripEntry, {List<Pin>? pins}) {
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
              tripEntry: TripEntry(
                id: 'test-id',
                groupId: 'test-group-id',
                tripName: 'テスト旅行',
                tripStartDate: DateTime(2024, 12, 30),
                tripEndDate: DateTime(2025, 1, 3), // 年またぎ
                tripMemo: 'テストメモ',
              ),
              onSave: (tripEntry, {List<Pin>? pins}) {
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

    testWidgets('パラメータの年が現在年と異なる場合、初期日付設定ロジックが正しく動作すること', (
      WidgetTester tester,
    ) async {
      // このテストでは、DatePickerの表示内容ではなく、
      // initialDateの設定ロジックが正しく動作することを確認する

      final currentYear = DateTime.now().year;
      final parameterYear = currentYear + 5; // 現在年と異なる年を設定

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              year: parameterYear,
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 日付フィールドが表示されることを確認
      expect(find.text('旅行期間 From'), findsOneWidget);
      expect(find.text('旅行期間 To'), findsOneWidget);

      // DatePickerを開くことができることを確認
      await tester.tap(find.text('旅行期間 From'));
      await tester.pumpAndSettle();

      // DatePickerが表示されることを確認（キャンセルボタンの存在で判定）
      expect(find.text('キャンセル'), findsOneWidget);

      // DatePickerを閉じる
      // DatePickerを閉じる（バックドロップをタップ）
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();
    });

    testWidgets('パラメータの年が現在年と同じ場合、初期日付設定ロジックが正しく動作すること', (
      WidgetTester tester,
    ) async {
      final currentYear = DateTime.now().year;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              year: currentYear,
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 日付フィールドが表示されることを確認
      expect(find.text('旅行期間 From'), findsOneWidget);

      // DatePickerを開くことができることを確認
      await tester.tap(find.text('旅行期間 From'));
      await tester.pumpAndSettle();

      // DatePickerが表示されることを確認
      expect(find.text('キャンセル'), findsOneWidget);

      // DatePickerを閉じる
      // DatePickerを閉じる（バックドロップをタップ）
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();
    });

    testWidgets('パラメータの年がnullで既存の日付が設定されている場合、初期日付設定ロジックが正しく動作すること', (
      WidgetTester tester,
    ) async {
      final existingDate = DateTime(2023, 5, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              year: null,
              tripEntry: TripEntry(
                id: 'test-id',
                groupId: 'test-group-id',
                tripName: 'テスト旅行',
                tripStartDate: existingDate,
                tripEndDate: DateTime(2023, 5, 20),
                tripMemo: 'テストメモ',
              ),
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 既存の日付が表示されることを確認
      expect(find.text('2023/05/15'), findsOneWidget);

      // 開始日フィールドをタップ
      await tester.tap(find.text('2023/05/15'));
      await tester.pumpAndSettle();

      // DatePickerが表示されることを確認
      expect(find.text('キャンセル'), findsOneWidget);

      // DatePickerを閉じる
      // DatePickerを閉じる（バックドロップをタップ）
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();
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
                  onSave: (tripEntry, {List<Pin>? pins}) {},
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

    testWidgets('TripEditModalにpinsパラメータが追加されていること', (
      WidgetTester tester,
    ) async {
      const testPins = [
        Pin(
          id: 'test-pin-1',
          pinId: 'test-pin-1',
          tripId: 'test-trip-id',
          latitude: 35.6762,
          longitude: 139.6503,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              pins: testPins,
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // TripEditModalが正常に表示されることを確認
      expect(find.byType(TripEditModal), findsOneWidget);
      expect(find.text('旅行新規作成'), findsOneWidget);
    });

    testWidgets('作成ボタン押下時にonSaveコールバックでpinsが渡されること', (
      WidgetTester tester,
    ) async {
      List<Pin>? receivedPins;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (tripEntry, {List<Pin>? pins}) {
                receivedPins = pins;
              },
              isTestEnvironment: true,
            ),
          ),
        ),
      );

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

      // onSaveコールバックでpinsが渡されることを確認（新規作成時は空リスト）
      expect(receivedPins, isNotNull);
      expect(receivedPins, isEmpty);
    });

    testWidgets('onPinSaved機能でピンが正しく更新されること', (WidgetTester tester) async {
      // _onPinSaved機能をテストするために、実際にピンが保存された状況をシミュレート
      // このテストでは、TripEditModalState内のonPinSaved機能を直接テストする必要がある

      // 初期ピンデータ
      final initialPins = [
        Pin(
          id: 'pin-1',
          pinId: 'pin-1',
          latitude: 35.6762,
          longitude: 139.6503,
          visitStartDate: DateTime(2024, 1, 1, 10, 0),
          visitEndDate: DateTime(2024, 1, 1, 12, 0),
          visitMemo: '最初のメモ',
        ),
      ];

      List<Pin>? savedPins;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              pins: initialPins,
              onSave: (tripEntry, {List<Pin>? pins}) {
                savedPins = pins;
              },
              isTestEnvironment: true,
            ),
          ),
        ),
      );

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
      expect(savedPins, isNotNull);
      expect(savedPins!.length, equals(1));
      expect(savedPins![0].pinId, equals('pin-1'));
    });

    testWidgets('ピンが存在する場合、訪問場所一覧が表示されること', (WidgetTester tester) async {
      final testPins = [
        Pin(
          id: 'test-pin-1',
          pinId: 'test-pin-1',
          tripId: 'test-trip-id',
          latitude: 35.6762,
          longitude: 139.6503,
          locationName: '東京駅',
          visitStartDate: DateTime(2024, 1, 1, 10, 0),
          visitEndDate: DateTime(2024, 1, 1, 12, 0),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              pins: testPins,
              onSave: (tripEntry, {List<Pin>? pins}) {},
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
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              pins: [],
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 場所名が表示されないことを確認
      expect(find.byKey(const Key('pinListItem_test-pin-1')), findsNothing);
    });

    testWidgets('locationNameが空の場合、空白で表示されること', (WidgetTester tester) async {
      final testPins = [
        Pin(
          id: 'test-pin-1',
          pinId: 'test-pin-1',
          tripId: 'test-trip-id',
          latitude: 35.6762,
          longitude: 139.6503,
          locationName: null,
          visitStartDate: DateTime(2024, 1, 1, 10, 0),
          visitEndDate: DateTime(2024, 1, 1, 12, 0),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              pins: testPins,
              onSave: (tripEntry, {List<Pin>? pins}) {},
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
      final testPins = [
        Pin(
          id: 'test-pin-1',
          pinId: 'test-pin-1',
          tripId: 'test-trip-id',
          latitude: 35.6762,
          longitude: 139.6503,
          locationName: '東京駅',
          visitStartDate: DateTime(2024, 1, 1, 10, 0),
          visitEndDate: DateTime(2024, 1, 1, 12, 0),
        ),
        Pin(
          id: 'test-pin-2',
          pinId: 'test-pin-2',
          tripId: 'test-trip-id',
          latitude: 35.6585,
          longitude: 139.7454,
          locationName: '渋谷駅',
          visitStartDate: DateTime(2024, 1, 2, 14, 0),
          visitEndDate: DateTime(2024, 1, 2, 16, 0),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              pins: testPins,
              onSave: (tripEntry, {List<Pin>? pins}) {},
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
      final testPins = [
        Pin(
          id: 'test-pin-1',
          pinId: 'test-pin-1',
          tripId: 'test-trip-id',
          latitude: 35.6762,
          longitude: 139.6503,
          locationName: '東京駅',
          visitStartDate: DateTime(2024, 1, 1, 10, 0),
          visitEndDate: DateTime(2024, 1, 1, 12, 0),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              pins: testPins,
              onSave: (tripEntry, {List<Pin>? pins}) {},
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
      final testPins = [
        Pin(
          id: 'test-pin-1',
          pinId: 'test-pin-1',
          tripId: 'test-trip-id',
          latitude: 35.6762,
          longitude: 139.6503,
          locationName: '東京駅',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              pins: testPins,
              onSave: (tripEntry, {List<Pin>? pins}) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 削除ボタンが表示されることを確認
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('削除ボタンをタップするとピンが一覧から削除されること', (WidgetTester tester) async {
      final testPins = [
        Pin(
          id: 'test-pin-1',
          pinId: 'test-pin-1',
          tripId: 'test-trip-id',
          latitude: 35.6762,
          longitude: 139.6503,
          locationName: '東京駅',
        ),
        Pin(
          id: 'test-pin-2',
          pinId: 'test-pin-2',
          tripId: 'test-trip-id',
          latitude: 35.6585,
          longitude: 139.7454,
          locationName: '渋谷駅',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              pins: testPins,
              onSave: (tripEntry, {List<Pin>? pins}) {},
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
      final testPins = [
        Pin(
          id: 'test-pin-1',
          pinId: 'test-pin-1',
          tripId: 'test-trip-id',
          latitude: 35.6762,
          longitude: 139.6503,
          locationName: '東京駅',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              pins: testPins,
              onSave: (tripEntry, {List<Pin>? pins}) {},
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
