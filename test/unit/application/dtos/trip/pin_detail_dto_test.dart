import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_detail_dto.dart';

void main() {
  group('PinDetailDto', () {
    test('必須パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const pinId = 'pin-123';

      // Act
      const dto = PinDetailDto(pinId: pinId);

      // Assert
      expect(dto.pinId, pinId);
      expect(dto.name, isNull);
      expect(dto.startDate, isNull);
      expect(dto.endDate, isNull);
      expect(dto.memo, isNull);
    });

    test('全パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const pinId = 'pin-123';
      const name = '訪問先の詳細';
      final startDate = DateTime(2024, 5, 1, 10);
      final endDate = DateTime(2024, 5, 1, 12);
      const memo = '詳細メモ';

      // Act
      final dto = PinDetailDto(
        pinId: pinId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        memo: memo,
      );

      // Assert
      expect(dto.pinId, pinId);
      expect(dto.name, name);
      expect(dto.startDate, startDate);
      expect(dto.endDate, endDate);
      expect(dto.memo, memo);
    });

    test('copyWithメソッドで必須パラメータが正しく更新される', () {
      // Arrange
      const originalDto = PinDetailDto(pinId: 'pin-123');

      // Act
      final copiedDto = originalDto.copyWith(pinId: 'pin-999');

      // Assert
      expect(copiedDto.pinId, 'pin-999');
      expect(copiedDto.name, isNull);
    });

    test('copyWithメソッドでオプショナルパラメータが正しく更新される', () {
      // Arrange
      final originalDto = PinDetailDto(
        pinId: 'pin-123',
        name: '元の名前',
        startDate: DateTime(2024, 5, 1, 10),
        endDate: DateTime(2024, 5, 1, 12),
        memo: '元のメモ',
      );

      // Act
      final copiedDto = originalDto.copyWith(
        name: '新しい名前',
        startDate: DateTime(2024, 5, 2, 10),
        endDate: DateTime(2024, 5, 2, 12),
        memo: '新しいメモ',
      );

      // Assert
      expect(copiedDto.pinId, 'pin-123');
      expect(copiedDto.name, '新しい名前');
      expect(copiedDto.startDate, DateTime(2024, 5, 2, 10));
      expect(copiedDto.endDate, DateTime(2024, 5, 2, 12));
      expect(copiedDto.memo, '新しいメモ');
    });

    test('copyWithメソッドでnullを指定しても元の値が保持される', () {
      // Arrange
      final originalDto = PinDetailDto(
        pinId: 'pin-123',
        name: '訪問詳細',
        startDate: DateTime(2024, 5, 1, 10),
        endDate: DateTime(2024, 5, 1, 12),
        memo: 'メモ',
      );

      // Act
      final copiedDto = originalDto.copyWith();

      // Assert
      expect(copiedDto.pinId, 'pin-123');
      expect(copiedDto.name, '訪問詳細');
      expect(copiedDto.startDate, DateTime(2024, 5, 1, 10));
      expect(copiedDto.endDate, DateTime(2024, 5, 1, 12));
      expect(copiedDto.memo, 'メモ');
    });

    test('同じ値を持つインスタンスは等しい', () {
      // Arrange
      const pinId = 'pin-123';
      const name = '訪問先の詳細';
      final startDate = DateTime(2024, 5, 1, 10);
      final endDate = DateTime(2024, 5, 1, 12);
      const memo = '詳細メモ';

      final dto1 = PinDetailDto(
        pinId: pinId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        memo: memo,
      );

      final dto2 = PinDetailDto(
        pinId: pinId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        memo: memo,
      );

      // Act & Assert
      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      // Arrange
      final dto1 = PinDetailDto(
        pinId: 'pin-123',
        name: '訪問先A',
        startDate: DateTime(2024, 5, 1, 10),
        endDate: DateTime(2024, 5, 1, 12),
        memo: 'メモA',
      );

      final dto2 = PinDetailDto(
        pinId: 'pin-999',
        name: '訪問先B',
        startDate: DateTime(2024, 5, 2, 10),
        endDate: DateTime(2024, 5, 2, 12),
        memo: 'メモB',
      );

      // Act & Assert
      expect(dto1, isNot(equals(dto2)));
      expect(dto1.hashCode, isNot(equals(dto2.hashCode)));
    });
  });
}
