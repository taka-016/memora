import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip_entry.dart';
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
      expect(find.text(''), findsNothing);
    });

    testWidgets('nameがある旅行の場合、「name yyyy/mm」形式で表示する', (
      WidgetTester tester,
    ) async {
      // Arrange
      final trips = [
        TripEntry(
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
      expect(find.text('北海道旅行 2023/08'), findsOneWidget);
    });

    testWidgets('nameがない旅行の場合、「yyyy/mm」形式で表示する', (WidgetTester tester) async {
      // Arrange
      final trips = [
        TripEntry(
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
      expect(find.text('2023/08'), findsOneWidget);
    });

    testWidgets('複数の旅行がある場合、すべて表示する', (WidgetTester tester) async {
      // Arrange
      final trips = [
        TripEntry(
          id: '1',
          groupId: 'group1',
          tripName: '北海道旅行',
          tripStartDate: DateTime(2023, 8, 15),
          tripEndDate: DateTime(2023, 8, 18),
        ),
        TripEntry(
          id: '2',
          groupId: 'group1',
          tripName: null,
          tripStartDate: DateTime(2023, 12, 25),
          tripEndDate: DateTime(2023, 12, 27),
        ),
      ];

      final widget = TripCell(
        trips: trips,
        availableHeight: 200.0,
        availableWidth: 200.0,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.text('北海道旅行 2023/08'), findsOneWidget);
      expect(find.text('2023/12'), findsOneWidget);
    });

    testWidgets('利用可能な高さが小さい場合、省略表示を行う', (WidgetTester tester) async {
      // Arrange
      final trips = List.generate(
        10,
        (index) => TripEntry(
          id: '$index',
          groupId: 'group1',
          tripName: '旅行$index',
          tripStartDate: DateTime(2023, index + 1, 1),
          tripEndDate: DateTime(2023, index + 1, 3),
        ),
      );

      final widget = TripCell(
        trips: trips,
        availableHeight: 50.0, // 小さい高さ
        availableWidth: 200.0,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      // 省略表示の場合、「...他x件」のような表示があることを確認
      expect(find.textContaining('他'), findsOneWidget);
    });
  });
}
