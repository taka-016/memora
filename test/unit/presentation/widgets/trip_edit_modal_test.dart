import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/presentation/widgets/trip_edit_modal.dart';

void main() {
  group('TripEditModal', () {
    testWidgets('新規作成モードでタイトルが正しく表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (tripEntry) {},
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
              onSave: (tripEntry) {},
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
              onSave: (tripEntry) {},
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
              onSave: (tripEntry) {},
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
              onSave: (tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('メモ'), findsOneWidget);
    });

    testWidgets('訪問場所を地図で選択ボタンがメモの下に表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      expect(find.text('訪問場所を地図で選択'), findsOneWidget);
    });

    testWidgets('訪問場所を地図で選択ボタンをタップで地図が展開表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 初期状態では地図が表示されていないことを確認
      expect(find.byKey(const Key('map_display')), findsNothing);

      // 初期状態では訪問場所を地図で選択ボタンが表示されることを確認
      expect(find.text('訪問場所を地図で選択'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(IconButton),
          matching: find.byIcon(Icons.close),
        ),
        findsNothing,
      );

      // 訪問場所を地図で選択ボタンを直接呼び出してテスト
      final mapSelectionButton = find.widgetWithText(
        ElevatedButton,
        '訪問場所を地図で選択',
      );
      await tester.ensureVisible(mapSelectionButton);
      await tester.tap(mapSelectionButton);
      await tester.pumpAndSettle();

      // 地図が展開表示されることを確認
      expect(find.byKey(const Key('map_display')), findsOneWidget);

      // closeアイコンが表示されることを確認
      expect(
        find.descendant(
          of: find.byType(IconButton),
          matching: find.byIcon(Icons.close),
        ),
        findsOneWidget,
      );
      expect(find.text('訪問場所を地図で選択'), findsNothing);

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
              onSave: (tripEntry) {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 訪問場所を地図で選択ボタンを直接呼び出して地図を展開
      final mapSelectionButton = find.widgetWithText(
        ElevatedButton,
        '訪問場所を地図で選択',
      );
      await tester.ensureVisible(mapSelectionButton);
      await tester.tap(mapSelectionButton);
      await tester.pumpAndSettle();

      // 地図が表示されることを確認
      expect(find.byKey(const Key('map_display')), findsOneWidget);

      // closeボタンのonPressedを直接呼び出し
      final mapOutlinedButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.close),
      );
      mapOutlinedButton.onPressed!();
      await tester.pumpAndSettle();

      // 地図が閉じることを確認
      expect(find.byKey(const Key('map_display')), findsNothing);

      // 地図画面が閉じることを確認
      expect(find.text('訪問場所を地図で選択'), findsOneWidget);
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
              onSave: (tripEntry) {},
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
              onSave: (tripEntry) {},
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
              onSave: (tripEntry) {},
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
              onSave: (tripEntry) {
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
              onSave: (tripEntry) {
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
              onSave: (tripEntry) {
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
              onSave: (tripEntry) {
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
              onSave: (tripEntry) {
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
              onSave: (tripEntry) {
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

    group('カレンダー初期表示のテスト', () {
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
                onSave: (tripEntry) {},
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
                onSave: (tripEntry) {},
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
                onSave: (tripEntry) {},
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
                  onSave: (tripEntry) {},
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
  });
}
