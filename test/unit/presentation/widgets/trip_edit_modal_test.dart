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
            ),
          ),
        ),
      );

      expect(find.text('メモ'), findsOneWidget);
    });

    testWidgets('新規作成時は「作成」ボタンが表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripEditModal(
              groupId: 'test-group-id',
              onSave: (tripEntry) {},
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
            ),
          ),
        ),
      );

      // 旅行名を入力
      await tester.enterText(find.byType(TextFormField).first, 'テスト旅行');

      // 開始日を設定
      await tester.tap(find.text('旅行期間 From'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 終了日を設定
      await tester.tap(find.text('旅行期間 To'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
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
  });
}
