import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/presentation/features/trip/trip_edit_modal.dart';

Widget _createApp({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('TripEditModal', () {
    testWidgets('新規作成モードでタイトルが正しく表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        _createApp(
          child: TripEditModal(
            groupId: 'test-group-id',
            groupMembers: const [],
            onSave: (TripEntryDto tripEntry) async {},
            isTestEnvironment: true,
          ),
        ),
      );

      expect(find.text('旅行新規作成'), findsOneWidget);
    });

    testWidgets('編集モードで既存旅行の情報がフォームに正しく表示されること', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'test-trip-id',
        groupId: 'test-group-id',
        year: 2024,
        name: 'テスト旅行',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 3),
        memo: 'テストメモ',
      );

      await tester.pumpWidget(
        _createApp(
          child: TripEditModal(
            groupId: 'test-group-id',
            groupMembers: const [],
            tripEntry: tripEntry,
            onSave: (TripEntryDto tripEntry) async {},
            isTestEnvironment: true,
          ),
        ),
      );

      expect(find.text('旅行編集'), findsOneWidget);
      expect(find.text('テスト旅行'), findsOneWidget);
      expect(find.text('2024/01/01'), findsOneWidget);
      expect(find.text('2024/01/03'), findsOneWidget);
      expect(find.text('テストメモ'), findsOneWidget);
    });

    testWidgets('旅行期間From、旅行期間Toの入力フィールドが表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        _createApp(
          child: TripEditModal(
            groupId: 'test-group-id',
            groupMembers: const [],
            onSave: (TripEntryDto tripEntry) async {},
            isTestEnvironment: true,
          ),
        ),
      );

      expect(find.text('旅行期間 From'), findsOneWidget);
      expect(find.text('旅行期間 To'), findsOneWidget);
    });

    testWidgets('旅行期間Fromのクリアボタンで開始日をクリアできること', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'trip-entry-1',
        groupId: 'test-group-id',
        year: 2024,
        startDate: DateTime(2024, 5, 1),
      );

      await tester.pumpWidget(
        _createApp(
          child: TripEditModal(
            groupId: 'test-group-id',
            groupMembers: const [],
            tripEntry: tripEntry,
            onSave: (TripEntryDto tripEntry) async {},
            isTestEnvironment: true,
          ),
        ),
      );

      expect(find.text('2024/05/01'), findsOneWidget);

      await tester.tap(find.byTooltip('旅行開始日をクリア'));
      await tester.pumpAndSettle();

      expect(find.text('旅行期間 From'), findsOneWidget);
    });

    testWidgets('旅行期間Toのクリアボタンで終了日をクリアできること', (WidgetTester tester) async {
      final tripEntry = TripEntryDto(
        id: 'trip-entry-1',
        groupId: 'test-group-id',
        year: 2024,
        endDate: DateTime(2024, 5, 3),
      );

      await tester.pumpWidget(
        _createApp(
          child: TripEditModal(
            groupId: 'test-group-id',
            groupMembers: const [],
            tripEntry: tripEntry,
            onSave: (TripEntryDto tripEntry) async {},
            isTestEnvironment: true,
          ),
        ),
      );

      expect(find.text('2024/05/03'), findsOneWidget);

      await tester.tap(find.byTooltip('旅行終了日をクリア'));
      await tester.pumpAndSettle();

      expect(find.text('旅行期間 To'), findsOneWidget);
    });

    testWidgets('作成ボタン押下時にonSaveコールバックが呼ばれること', (WidgetTester tester) async {
      TripEntryDto? savedTripEntry;

      await tester.pumpWidget(
        _createApp(
          child: TripEditModal(
            groupId: 'test-group-id',
            groupMembers: const [],
            year: 2024,
            onSave: (TripEntryDto tripEntry) async {
              savedTripEntry = tripEntry;
            },
            isTestEnvironment: true,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'テスト旅行');
      await tester.tap(find.text('作成'));
      await tester.pumpAndSettle();

      expect(savedTripEntry, isNotNull);
      expect(savedTripEntry!.name, 'テスト旅行');
      expect(savedTripEntry!.groupId, 'test-group-id');
      expect(savedTripEntry!.year, 2024);
    });

    testWidgets('開始日が終了日より後の場合はエラーを表示し保存しないこと', (WidgetTester tester) async {
      var saveCallCount = 0;

      await tester.pumpWidget(
        _createApp(
          child: TripEditModal(
            groupId: 'test-group-id',
            groupMembers: const [],
            tripEntry: TripEntryDto(
              id: 'trip-id',
              groupId: 'test-group-id',
              year: 2024,
              startDate: DateTime(2024, 1, 3),
              endDate: DateTime(2024, 1, 1),
            ),
            onSave: (TripEntryDto tripEntry) async {
              saveCallCount += 1;
            },
            isTestEnvironment: true,
          ),
        ),
      );

      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      expect(find.text('開始日は終了日より前の日付を選択してください'), findsOneWidget);
      expect(saveCallCount, 0);
    });

    testWidgets('保存時のバリデーションエラーはモーダル内に表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        _createApp(
          child: TripEditModal(
            groupId: 'test-group-id',
            groupMembers: const [],
            tripEntry: const TripEntryDto(
              id: 'trip-id',
              groupId: 'test-group-id',
              year: 2024,
              name: 'テスト旅行',
            ),
            onSave: (TripEntryDto tripEntry) async {
              throw const ApplicationValidationException('旅行名は必須です');
            },
            isTestEnvironment: true,
          ),
        ),
      );

      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      expect(find.text('旅行編集'), findsOneWidget);
      expect(find.text('旅行名は必須です'), findsOneWidget);
    });

    testWidgets('旅程ボタンをタップで旅程画面が表示され閉じると旅行編集へ戻ること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createApp(
          child: TripEditModal(
            groupId: 'test-group-id',
            groupMembers: const [],
            tripEntry: TripEntryDto(
              id: 'trip-1',
              groupId: 'test-group-id',
              year: 2024,
              itineraryItems: [
                ItineraryItemDto(
                  id: 'item-1',
                  tripId: 'trip-1',
                  name: '朝食',
                  startDateTime: DateTime(2024, 1, 2, 8),
                  endDateTime: DateTime(2024, 1, 2, 9),
                  memo: 'ホテルで朝食',
                ),
              ],
            ),
            onSave: (TripEntryDto tripEntry) async {},
            isTestEnvironment: true,
          ),
        ),
      );

      final itineraryButton = find.widgetWithText(ElevatedButton, '旅程');
      await tester.ensureVisible(itineraryButton);
      await tester.tap(itineraryButton);
      await tester.pumpAndSettle();

      expect(find.text('旅程'), findsOneWidget);
      expect(find.text('朝食'), findsOneWidget);
      expect(find.text('08:00 - 09:00'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('旅行編集'), findsOneWidget);
      expect(find.text('更新'), findsOneWidget);
    });

    testWidgets('タスクボタンをタップでタスク画面が表示され閉じると旅行編集へ戻ること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createApp(
          child: TripEditModal(
            groupId: 'test-group-id',
            groupMembers: [
              GroupMemberDto(
                memberId: 'member-1',
                groupId: 'test-group-id',
                displayName: '太郎',
                email: 'taro@example.com',
              ),
            ],
            tripEntry: const TripEntryDto(
              id: 'trip-1',
              groupId: 'test-group-id',
              year: 2024,
              tasks: [
                TaskDto(
                  id: 'task-1',
                  tripId: 'trip-1',
                  orderIndex: 0,
                  name: '予約確認',
                  isCompleted: false,
                ),
              ],
            ),
            onSave: (TripEntryDto tripEntry) async {},
            isTestEnvironment: true,
          ),
        ),
      );

      final taskButton = find.widgetWithText(ElevatedButton, 'タスク');
      await tester.ensureVisible(taskButton);
      await tester.tap(taskButton);
      await tester.pumpAndSettle();

      expect(find.text('タスク管理'), findsOneWidget);
      expect(find.text('予約確認'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('旅行編集'), findsOneWidget);
      expect(find.text('更新'), findsOneWidget);
    });
  });
}
