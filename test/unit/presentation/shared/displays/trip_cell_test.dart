import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/shared/displays/trip_cell.dart';

void main() {
  group('TripCell', () {
    testWidgets('旅行データが空の場合、空のContainerを表示する', (WidgetTester tester) async {
      // Arrange
      final widget = TripCell(
        trips: [],
        availableHeight: 100.0,
        availableWidth: 200.0,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.byType(Container), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.child, isNull);
    });

    testWidgets('旅行名がある場合、日付と旅行名を2行で表示する', (WidgetTester tester) async {
      // Arrange
      final trips = [
        TripEntryDto(
          id: '1',
          groupId: 'group1',
          tripName: '北海道旅行',
          tripStartDate: DateTime(2023, 8, 15),
          tripEndDate: DateTime(2023, 8, 18),
        ),
      ];

      final widget = TripCell(
        trips: trips,
        availableHeight: 100.0,
        availableWidth: 200.0,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.text('2023/08/15'), findsOneWidget);
      expect(find.text('北海道旅行'), findsOneWidget);
    });

    testWidgets('旅行名がない場合、「旅行名未設定」と表示する', (WidgetTester tester) async {
      // Arrange
      final trips = [
        TripEntryDto(
          id: '1',
          groupId: 'group1',
          tripName: null,
          tripStartDate: DateTime(2023, 8, 15),
          tripEndDate: DateTime(2023, 8, 18),
        ),
      ];

      final widget = TripCell(
        trips: trips,
        availableHeight: 100.0,
        availableWidth: 200.0,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.text('2023/08/15'), findsOneWidget);
      expect(find.text('旅行名未設定'), findsOneWidget);
    });

    testWidgets('複数の旅行がある場合、高さに収まる分だけ表示する', (WidgetTester tester) async {
      // Arrange
      final trips = [
        TripEntryDto(
          id: '1',
          groupId: 'group1',
          tripName: '北海道旅行',
          tripStartDate: DateTime(2023, 8, 15),
          tripEndDate: DateTime(2023, 8, 18),
        ),
        TripEntryDto(
          id: '2',
          groupId: 'group1',
          tripName: '沖縄旅行',
          tripStartDate: DateTime(2023, 12, 25),
          tripEndDate: DateTime(2023, 12, 27),
        ),
      ];

      final widget = TripCell(
        trips: trips,
        availableHeight: 200.0, // 十分な高さ
        availableWidth: 200.0,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.text('2023/08/15'), findsOneWidget);
      expect(find.text('北海道旅行'), findsOneWidget);
      expect(find.text('2023/12/25'), findsOneWidget);
      expect(find.text('沖縄旅行'), findsOneWidget);
    });

    testWidgets('利用可能な高さが小さい場合、省略表示を行う', (WidgetTester tester) async {
      // Arrange
      final trips = List.generate(
        10,
        (index) => TripEntryDto(
          id: '$index',
          groupId: 'group1',
          tripName: '旅行$index',
          tripStartDate: DateTime(2023, index + 1, 1),
          tripEndDate: DateTime(2023, index + 1, 3),
        ),
      );

      final widget = TripCell(
        trips: trips,
        availableHeight: 64.0, // 2つのアイテムだけ表示できる高さ（32.0 * 2）
        availableWidth: 200.0,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      // 最初の1件は表示される
      expect(find.text('2023/01/01'), findsOneWidget);
      expect(find.text('旅行0'), findsOneWidget);
      // 省略表示が表示される
      expect(find.textContaining('...他9件'), findsOneWidget);
    });

    testWidgets('利用可能な高さが0以下の場合、空のContainerを表示する', (WidgetTester tester) async {
      // Arrange
      final trips = [
        TripEntryDto(
          id: '1',
          groupId: 'group1',
          tripName: '北海道旅行',
          tripStartDate: DateTime(2023, 8, 15),
          tripEndDate: DateTime(2023, 8, 18),
        ),
      ];

      final widget = TripCell(
        trips: trips,
        availableHeight: 0.0,
        availableWidth: 200.0,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.byType(Container), findsAtLeastNWidgets(1));
      // 旅行データは表示されない
      expect(find.text('2023/08/15'), findsNothing);
      expect(find.text('北海道旅行'), findsNothing);
    });

    testWidgets('日付フォーマットが正しく適用される', (WidgetTester tester) async {
      // Arrange
      final trips = [
        TripEntryDto(
          id: '1',
          groupId: 'group1',
          tripName: 'テスト旅行',
          tripStartDate: DateTime(2023, 1, 5), // 1桁の月・日をテスト
          tripEndDate: DateTime(2023, 1, 7),
        ),
      ];

      final widget = TripCell(
        trips: trips,
        availableHeight: 100.0,
        availableWidth: 200.0,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.text('2023/01/05'), findsOneWidget); // ゼロパディングされている
      expect(find.text('テスト旅行'), findsOneWidget);
    });
  });
}
