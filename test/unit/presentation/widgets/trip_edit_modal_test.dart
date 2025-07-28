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
  });
}
