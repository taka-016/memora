import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/trip/trip_edit_modal.dart';

Widget _createApp({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('TripEditModal', () {
    testWidgets('新規作成モードでタイトルが正しく表示されること', (tester) async {
      await tester.pumpWidget(
        _createApp(
          child: TripEditModal(
            groupId: 'test-group-id',
            groupMembers: const [],
            onSave: (tripEntry) async {},
            isTestEnvironment: true,
          ),
        ),
      );

      expect(find.text('旅行新規作成'), findsOneWidget);
    });

    testWidgets('編集モードで既存旅行の情報がフォームに表示されること', (tester) async {
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
            onSave: (tripEntry) async {},
            isTestEnvironment: true,
          ),
        ),
      );

      expect(find.text('旅行編集'), findsOneWidget);
      expect(find.text('テスト旅行'), findsOneWidget);
      expect(find.text('テストメモ'), findsOneWidget);
    });

    testWidgets('旅行編集画面に訪問場所マップを表示すること', (tester) async {
      await tester.pumpWidget(
        _createApp(
          child: TripEditModal(
            groupId: 'test-group-id',
            groupMembers: const [],
            onSave: (tripEntry) async {},
            isTestEnvironment: true,
          ),
        ),
      );

      expect(find.text('訪問場所'), findsOneWidget);
      expect(find.byKey(const Key('trip_locations_map')), findsOneWidget);
      expect(find.byKey(const Key('map_view')), findsOneWidget);
    });

    testWidgets('旅程ボタンをタップで旅程画面が表示され閉じると旅行編集へ戻ること', (tester) async {
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
            onSave: (tripEntry) async {},
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

    testWidgets('入力した旅行情報を保存できること', (tester) async {
      TripEntryDto? savedTripEntry;

      await tester.pumpWidget(
        _createApp(
          child: TripEditModal(
            groupId: 'test-group-id',
            groupMembers: const [],
            year: 2024,
            onSave: (tripEntry) async {
              savedTripEntry = tripEntry;
            },
            isTestEnvironment: true,
          ),
        ),
      );

      await tester.enterText(find.widgetWithText(TextFormField, '旅行名'), '沖縄旅行');
      await tester.enterText(find.widgetWithText(TextFormField, 'メモ'), '家族旅行');
      await tester.tap(find.text('作成'));
      await tester.pumpAndSettle();

      expect(savedTripEntry, isNotNull);
      expect(savedTripEntry!.name, '沖縄旅行');
      expect(savedTripEntry!.memo, '家族旅行');
    });
  });
}
