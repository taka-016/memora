import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/copy_with_helper.dart';

void main() {
  group('resolveCopyWithValue', () {
    test('プレースホルダーが渡された場合は現在値を返す', () {
      const currentValue = 'current';
      final result = resolveCopyWithValue<String>(
        copyWithPlaceholder,
        currentValue,
        'field',
      );
      expect(result, currentValue);
    });

    test('nullが渡された場合はnullを返す', () {
      const currentValue = 'current';
      final result = resolveCopyWithValue<String>(
        null,
        currentValue,
        'field',
      );
      expect(result, isNull);
    });

    test('正しい型の値が渡された場合はその値を返す', () {
      const currentValue = 'current';
      const newValue = 'new';
      final result = resolveCopyWithValue<String>(
        newValue,
        currentValue,
        'field',
      );
      expect(result, newValue);
    });

    test('不正な型の値が渡された場合はArgumentErrorをスローする', () {
      const currentValue = 'current';
      expect(
        () => resolveCopyWithValue<String>(
          123,
          currentValue,
          'testField',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('型が不正です'),
          ),
        ),
      );
    });

    test('DateTime型で正しく動作する', () {
      final currentValue = DateTime(2024, 1, 1);
      final newValue = DateTime(2025, 1, 1);

      final result = resolveCopyWithValue<DateTime>(
        newValue,
        currentValue,
        'dateField',
      );
      expect(result, newValue);
    });

    test('List型で正しく動作する', () {
      const currentValue = ['a', 'b'];
      const newValue = ['c', 'd'];

      final result = resolveCopyWithValue<List<String>>(
        newValue,
        currentValue,
        'listField',
      );
      expect(result, newValue);
    });

    test('nullable型でプレースホルダーの場合は現在のnull値を返す', () {
      const String? currentValue = null;
      final result = resolveCopyWithValue<String>(
        copyWithPlaceholder,
        currentValue,
        'field',
      );
      expect(result, isNull);
    });

    test('nullable型で新しいnullを明示的に設定できる', () {
      const currentValue = 'current';
      final result = resolveCopyWithValue<String>(
        null,
        currentValue,
        'field',
      );
      expect(result, isNull);
    });
  });
}
