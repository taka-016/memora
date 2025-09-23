import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/formatters/japanese_era_formatter.dart';

void main() {
  group('JapaneseEraFormatter', () {
    test('令和時代の日付をフォーマットできる', () {
      // Arrange
      final date = DateTime(2024, 7, 21);

      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatter(date);

      // Assert
      expect(result, '令和6年7月21日');
    });

    test('令和元年の日付をフォーマットできる', () {
      // Arrange
      final date = DateTime(2019, 5, 1);

      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatter(date);

      // Assert
      expect(result, '令和元年5月1日');
    });

    test('平成時代の日付をフォーマットできる', () {
      // Arrange
      final date = DateTime(2018, 12, 31);

      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatter(date);

      // Assert
      expect(result, '平成30年12月31日');
    });

    test('平成元年の日付をフォーマットできる', () {
      // Arrange
      final date = DateTime(1989, 1, 8);

      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatter(date);

      // Assert
      expect(result, '平成元年1月8日');
    });

    test('昭和時代の日付をフォーマットできる', () {
      // Arrange
      final date = DateTime(1988, 12, 31);

      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatter(date);

      // Assert
      expect(result, '昭和63年12月31日');
    });

    test('昭和元年の日付をフォーマットできる', () {
      // Arrange
      final date = DateTime(1926, 12, 25);

      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatter(date);

      // Assert
      expect(result, '昭和元年12月25日');
    });

    test('大正時代の日付をフォーマットできる', () {
      // Arrange
      final date = DateTime(1920, 1, 1);

      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatter(date);

      // Assert
      expect(result, '大正9年1月1日');
    });

    test('大正元年の日付をフォーマットできる', () {
      // Arrange
      final date = DateTime(1912, 7, 30);

      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatter(date);

      // Assert
      expect(result, '大正元年7月30日');
    });

    test('明治時代の日付をフォーマットできる', () {
      // Arrange
      final date = DateTime(1900, 1, 1);

      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatter(date);

      // Assert
      expect(result, '明治33年1月1日');
    });

    test('明治元年の日付をフォーマットできる', () {
      // Arrange
      final date = DateTime(1868, 1, 25);

      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatter(date);

      // Assert
      expect(result, '明治元年1月25日');
    });

    test('明治以前の日付は西暦で表示される', () {
      // Arrange
      final date = DateTime(1867, 12, 31);

      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatter(date);

      // Assert
      expect(result, '1867年12月31日');
    });

    test('現在の年を和暦年表示用にフォーマットできる', () {
      // Arrange
      final currentYear = DateTime.now().year;

      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatterYear(
        currentYear,
      );

      // Assert
      // 現在の年に対応する和暦フォーマットが返される（年号を含む）
      expect(result, matches(r'[令和平成昭和大正明治].*年'));
    });

    test('令和6年(2024年)を正しくフォーマットできる', () {
      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatterYear(2024);

      // Assert
      expect(result, '令和6年');
    });

    test('令和元年(2019年)を正しくフォーマットできる', () {
      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatterYear(2019);

      // Assert
      expect(result, '令和元年');
    });

    test('平成30年(2018年)を正しくフォーマットできる', () {
      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatterYear(2018);

      // Assert
      expect(result, '平成30年');
    });

    test('平成元年(1989年)を正しくフォーマットできる', () {
      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatterYear(1989);

      // Assert
      expect(result, '平成元年');
    });

    test('昭和63年(1988年)を正しくフォーマットできる', () {
      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatterYear(1988);

      // Assert
      expect(result, '昭和63年');
    });

    test('大正9年(1920年)を正しくフォーマットできる', () {
      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatterYear(1920);

      // Assert
      expect(result, '大正9年');
    });

    test('明治33年(1900年)を正しくフォーマットできる', () {
      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatterYear(1900);

      // Assert
      expect(result, '明治33年');
    });

    test('明治以前(1867年)は西暦年のみ表示される', () {
      // Act
      final result = JapaneseEraFormatter.formatJapaneseEraFormatterYear(1867);

      // Assert
      expect(result, '1867年');
    });
  });
}
