import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/trip_row.dart';

void main() {
  group('TripRow', () {
    testWidgets('旅行データが空の場合、空のContainerを表示する', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTripRowWidget(trips: const [], availableHeight: 100),
      );

      expect(find.byType(Container), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.child, isNull);
    });

    testWidgets('旅行名がある場合、日付と旅行名を2行で表示する', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTripRowWidget(
          trips: [
            TripEntryDto(
              id: '1',
              groupId: 'group1',
              tripYear: 2023,
              tripName: '北海道旅行',
              tripStartDate: DateTime(2023, 8, 15),
              tripEndDate: DateTime(2023, 8, 18),
            ),
          ],
          availableHeight: 100,
        ),
      );

      expect(find.text('2023/08/15'), findsOneWidget);
      expect(find.text('北海道旅行'), findsOneWidget);
    });

    testWidgets('旅行名がない場合、「旅行名未設定」と表示する', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTripRowWidget(
          trips: [
            TripEntryDto(
              id: '1',
              groupId: 'group1',
              tripYear: 2023,
              tripName: null,
              tripStartDate: DateTime(2023, 8, 15),
              tripEndDate: DateTime(2023, 8, 18),
            ),
          ],
          availableHeight: 100,
        ),
      );

      expect(find.text('2023/08/15'), findsOneWidget);
      expect(find.text('旅行名未設定'), findsOneWidget);
    });

    testWidgets('複数の旅行がある場合、高さに収まる分だけ表示する', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTripRowWidget(
          trips: [
            TripEntryDto(
              id: '1',
              groupId: 'group1',
              tripYear: 2023,
              tripName: '北海道旅行',
              tripStartDate: DateTime(2023, 8, 15),
              tripEndDate: DateTime(2023, 8, 18),
            ),
            TripEntryDto(
              id: '2',
              groupId: 'group1',
              tripYear: 2023,
              tripName: '沖縄旅行',
              tripStartDate: DateTime(2023, 12, 25),
              tripEndDate: DateTime(2023, 12, 27),
            ),
          ],
          availableHeight: 200,
        ),
      );

      expect(find.text('2023/08/15'), findsOneWidget);
      expect(find.text('北海道旅行'), findsOneWidget);
      expect(find.text('2023/12/25'), findsOneWidget);
      expect(find.text('沖縄旅行'), findsOneWidget);
    });

    testWidgets('利用可能な高さが小さい場合、省略表示を行う', (WidgetTester tester) async {
      final trips = List.generate(
        10,
        (index) => TripEntryDto(
          id: '$index',
          groupId: 'group1',
          tripYear: 2023,
          tripName: '旅行$index',
          tripStartDate: DateTime(2023, index + 1),
          tripEndDate: DateTime(2023, index + 1, 3),
        ),
      );

      await tester.pumpWidget(
        _buildTripRowWidget(trips: trips, availableHeight: 64),
      );

      expect(find.text('2023/01/01'), findsOneWidget);
      expect(find.text('旅行0'), findsOneWidget);
      expect(find.textContaining('…他9件'), findsOneWidget);
    });

    testWidgets('利用可能な高さが0以下の場合、旅行データを表示しない', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTripRowWidget(
          trips: [
            TripEntryDto(
              id: '1',
              groupId: 'group1',
              tripYear: 2023,
              tripName: '北海道旅行',
              tripStartDate: DateTime(2023, 8, 15),
              tripEndDate: DateTime(2023, 8, 18),
            ),
          ],
          availableHeight: 0,
        ),
      );

      expect(find.text('2023/08/15'), findsNothing);
      expect(find.text('北海道旅行'), findsNothing);
    });

    testWidgets('日付フォーマットが正しく適用される', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTripRowWidget(
          trips: [
            TripEntryDto(
              id: '1',
              groupId: 'group1',
              tripYear: 2023,
              tripName: 'テスト旅行',
              tripStartDate: DateTime(2023, 1, 5),
              tripEndDate: DateTime(2023, 1, 7),
            ),
          ],
          availableHeight: 100,
        ),
      );

      expect(find.text('2023/01/05'), findsOneWidget);
      expect(find.text('テスト旅行'), findsOneWidget);
    });

    testWidgets('旅行期間未設定の場合は年と共に未設定表示を行う', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTripRowWidget(
          trips: const [
            TripEntryDto(
              id: '1',
              groupId: 'group1',
              tripYear: 2023,
              tripName: '期間未設定の旅行',
            ),
          ],
          availableHeight: 100,
        ),
      );

      expect(find.text('2023年 (期間未設定)'), findsOneWidget);
      expect(find.text('期間未設定の旅行'), findsOneWidget);
    });
  });
}

Widget _buildTripRowWidget({
  required List<TripEntryDto> trips,
  required double availableHeight,
  double availableWidth = 200,
}) {
  final row = const TripRow(initialHeight: 100);
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return row.buildYearCell(
            context: context,
            rowContext: _rowContext(trips: trips),
            year: 2023,
            rowHeight: availableHeight,
            yearColumnWidth: availableWidth,
          );
        },
      ),
    ),
  );
}

TimelineRowContext _rowContext({required List<TripEntryDto> trips}) {
  return TimelineRowContext(
    groupId: 'group1',
    tripsByYear: {2023: trips},
    dvcPointUsagesByYear: const {},
    groupEventsByYear: const {},
    buildMemberLabels:
        ({
          required DateTime? birthday,
          required String? gender,
          required int targetYear,
        }) {
          return const [];
        },
    saveGroupEvent:
        ({
          required currentEvent,
          required groupId,
          required selectedYear,
          required memo,
        }) async {},
  );
}
