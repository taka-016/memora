import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/presentation/features/trip/itinerary_view.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 480, height: 720, child: child)),
  );
}

final _uuidV7Pattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  group('ItineraryView', () {
    testWidgets('ヘッダーと旅程項目を開始日時順で表示すること', (tester) async {
      final items = [
        ItineraryItemDto(
          id: 'item-no-start',
          tripId: 'trip-1',
          name: '未定',
          memo: '現地で決める',
        ),
        ItineraryItemDto(
          id: 'item-2',
          tripId: 'trip-1',
          name: '首里城観光',
          startDateTime: DateTime(2024, 1, 2, 10),
          endDateTime: DateTime(2024, 1, 2, 12),
          memo: 'チケットを確認',
        ),
        ItineraryItemDto(
          id: 'item-1',
          tripId: 'trip-1',
          name: '朝食',
          startDateTime: DateTime(2024, 1, 2, 8),
          endDateTime: DateTime(2024, 1, 2, 9),
          memo: 'ホテルで朝食',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: items,
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      expect(find.text('旅程'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('朝食'), findsOneWidget);
      expect(find.text('01/02 08:00 - 01/02 09:00'), findsOneWidget);
      expect(find.text('ホテルで朝食'), findsOneWidget);

      final first = tester.getTopLeft(find.text('朝食')).dy;
      final second = tester.getTopLeft(find.text('首里城観光')).dy;
      final last = tester.getTopLeft(find.text('未定')).dy;
      expect(first, lessThan(second));
      expect(second, lessThan(last));
    });

    testWidgets('旅程項目を追加して親へ通知すること', (tester) async {
      List<ItineraryItemDto> lastChanged = [];

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: const [],
            onChanged: (updated) => lastChanged = updated,
            onClose: () {},
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('itinerary_name_field')),
        '朝食',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, '追加'));
      await tester.pumpAndSettle();

      expect(lastChanged, hasLength(1));
      expect(_uuidV7Pattern.hasMatch(lastChanged.first.id), isTrue);
      expect(lastChanged.first.tripId, 'trip-1');
      expect(lastChanged.first.name, '朝食');
      expect(lastChanged.first.startDateTime, isNull);
      expect(lastChanged.first.endDateTime, isNull);
      expect(lastChanged.first.memo, isNull);
    });

    testWidgets('追加用フォームは項目名のみ表示されること', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: const [],
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('itinerary_name_field')), findsOneWidget);
      expect(find.byKey(const Key('itinerary_start_date_field')), findsNothing);
      expect(find.byKey(const Key('itinerary_start_time_field')), findsNothing);
      expect(find.byKey(const Key('itinerary_end_date_field')), findsNothing);
      expect(find.byKey(const Key('itinerary_end_time_field')), findsNothing);
      expect(find.byKey(const Key('itinerary_memo_field')), findsNothing);
      expect(
        find.byKey(const Key('itinerary_start_datetime_field')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('itinerary_end_datetime_field')),
        findsNothing,
      );
      expect(find.text('日付を選択'), findsNothing);
      expect(find.text('時間を選択'), findsNothing);
    });

    testWidgets('旅程項目名が未入力の場合は追加できないこと', (tester) async {
      var changeCount = 0;

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: const [],
            onChanged: (_) => changeCount += 1,
            onClose: () {},
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, '追加'));
      await tester.pumpAndSettle();

      expect(find.text('旅程項目名を入力してください'), findsOneWidget);
      expect(changeCount, 0);
    });

    testWidgets('旅程項目を編集・削除できること', (tester) async {
      List<ItineraryItemDto> lastChanged = [];
      final item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
        endDateTime: DateTime(2024, 1, 2, 9),
        memo: 'ホテルで朝食',
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: [item],
            onChanged: (updated) => lastChanged = updated,
            onClose: () {},
          ),
        ),
      );

      final listItem = find.byKey(const Key('itineraryListItem_item-1'));
      await tester.ensureVisible(listItem);
      await tester.tap(listItem);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('itinerary_edit_name_field')),
        '朝食変更',
      );
      await tester.enterText(
        find.byKey(const Key('itinerary_edit_memo_field')),
        '予約時間に合わせる',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, '保存'));
      await tester.pumpAndSettle();

      expect(lastChanged, hasLength(1));
      expect(lastChanged.first.id, 'item-1');
      expect(lastChanged.first.name, '朝食変更');
      expect(lastChanged.first.startDateTime, DateTime(2024, 1, 2, 8));
      expect(lastChanged.first.memo, '予約時間に合わせる');

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: lastChanged,
            onChanged: (updated) => lastChanged = updated,
            onClose: () {},
          ),
        ),
      );

      final updatedListItem = find.byKey(const Key('itineraryListItem_item-1'));
      await tester.ensureVisible(updatedListItem);
      await tester.tap(updatedListItem);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '削除'));
      await tester.pumpAndSettle();

      expect(lastChanged, isEmpty);
    });

    testWidgets('編集用の開始日時と終了日時は日付・時刻選択フィールドで初期表示されること', (tester) async {
      final item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
        endDateTime: DateTime(2024, 1, 2, 9),
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: [item],
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      final listItem = find.byKey(const Key('itineraryListItem_item-1'));
      await tester.ensureVisible(listItem);
      await tester.tap(listItem);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('itinerary_edit_start_date_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('itinerary_edit_start_time_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('itinerary_edit_end_date_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('itinerary_edit_end_time_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('itinerary_edit_start_datetime_field')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('itinerary_edit_end_datetime_field')),
        findsNothing,
      );
      expect(find.text('2024/01/02'), findsNWidgets(2));
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
    });
  });
}
