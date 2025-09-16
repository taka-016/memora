import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';

void main() {
  group('PinDto', () {
    test('必須パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const pinId = 'pin-123';
      const latitude = 35.6762;
      const longitude = 139.6503;

      // Act
      final pinDto = PinDto(
        pinId: pinId,
        latitude: latitude,
        longitude: longitude,
      );

      // Assert
      expect(pinDto.pinId, pinId);
      expect(pinDto.latitude, latitude);
      expect(pinDto.longitude, longitude);
      expect(pinDto.id, isNull);
      expect(pinDto.tripId, isNull);
      expect(pinDto.groupId, isNull);
      expect(pinDto.locationName, isNull);
      expect(pinDto.visitStartDate, isNull);
      expect(pinDto.visitEndDate, isNull);
      expect(pinDto.visitMemo, isNull);
    });

    test('全パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const id = 'id-123';
      const pinId = 'pin-123';
      const tripId = 'trip-456';
      const groupId = 'group-789';
      const latitude = 35.6762;
      const longitude = 139.6503;
      const locationName = '東京駅';
      final visitStartDate = DateTime(2024, 1, 1, 10, 0);
      final visitEndDate = DateTime(2024, 1, 1, 12, 0);
      const visitMemo = '観光で訪問';

      // Act
      final pinDto = PinDto(
        id: id,
        pinId: pinId,
        tripId: tripId,
        groupId: groupId,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        visitStartDate: visitStartDate,
        visitEndDate: visitEndDate,
        visitMemo: visitMemo,
      );

      // Assert
      expect(pinDto.id, id);
      expect(pinDto.pinId, pinId);
      expect(pinDto.tripId, tripId);
      expect(pinDto.groupId, groupId);
      expect(pinDto.latitude, latitude);
      expect(pinDto.longitude, longitude);
      expect(pinDto.locationName, locationName);
      expect(pinDto.visitStartDate, visitStartDate);
      expect(pinDto.visitEndDate, visitEndDate);
      expect(pinDto.visitMemo, visitMemo);
    });

    test('copyWithメソッドで必須パラメータが正しく更新される', () {
      // Arrange
      final originalDto = PinDto(
        pinId: 'original-pin',
        latitude: 35.6762,
        longitude: 139.6503,
      );

      // Act
      final copiedDto = originalDto.copyWith(
        pinId: 'updated-pin',
        latitude: 35.0,
        longitude: 139.0,
      );

      // Assert
      expect(copiedDto.pinId, 'updated-pin');
      expect(copiedDto.latitude, 35.0);
      expect(copiedDto.longitude, 139.0);
    });

    test('copyWithメソッドでオプショナルパラメータが正しく更新される', () {
      // Arrange
      final originalDto = PinDto(
        pinId: 'pin-123',
        latitude: 35.6762,
        longitude: 139.6503,
        locationName: '元の場所名',
        visitMemo: '元のメモ',
      );

      // Act
      final copiedDto = originalDto.copyWith(
        locationName: '新しい場所名',
        visitMemo: '新しいメモ',
      );

      // Assert
      expect(copiedDto.pinId, 'pin-123');
      expect(copiedDto.latitude, 35.6762);
      expect(copiedDto.longitude, 139.6503);
      expect(copiedDto.locationName, '新しい場所名');
      expect(copiedDto.visitMemo, '新しいメモ');
    });

    test('copyWithメソッドでnullを指定しても元の値が保持される', () {
      // Arrange
      final originalDto = PinDto(
        id: 'id-123',
        pinId: 'pin-123',
        tripId: 'trip-456',
        groupId: 'group-789',
        latitude: 35.6762,
        longitude: 139.6503,
        locationName: '東京駅',
        visitMemo: '観光で訪問',
      );

      // Act
      final copiedDto = originalDto.copyWith();

      // Assert
      expect(copiedDto.id, 'id-123');
      expect(copiedDto.pinId, 'pin-123');
      expect(copiedDto.tripId, 'trip-456');
      expect(copiedDto.groupId, 'group-789');
      expect(copiedDto.latitude, 35.6762);
      expect(copiedDto.longitude, 139.6503);
      expect(copiedDto.locationName, '東京駅');
      expect(copiedDto.visitMemo, '観光で訪問');
    });

    test('同じ値を持つインスタンスは等しい', () {
      // Arrange
      const id = 'id-123';
      const pinId = 'pin-123';
      const tripId = 'trip-456';
      const groupId = 'group-789';
      const latitude = 35.6762;
      const longitude = 139.6503;
      const locationName = '東京駅';
      final visitStartDate = DateTime(2024, 1, 1, 10, 0);
      final visitEndDate = DateTime(2024, 1, 1, 12, 0);
      const visitMemo = '観光で訪問';

      final dto1 = PinDto(
        id: id,
        pinId: pinId,
        tripId: tripId,
        groupId: groupId,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        visitStartDate: visitStartDate,
        visitEndDate: visitEndDate,
        visitMemo: visitMemo,
      );

      final dto2 = PinDto(
        id: id,
        pinId: pinId,
        tripId: tripId,
        groupId: groupId,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        visitStartDate: visitStartDate,
        visitEndDate: visitEndDate,
        visitMemo: visitMemo,
      );

      // Act & Assert
      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      // Arrange
      final dto1 = PinDto(
        id: 'id-123',
        pinId: 'pin-123',
        tripId: 'trip-456',
        groupId: 'group-789',
        latitude: 35.6762,
        longitude: 139.6503,
        locationName: '東京駅',
        visitMemo: '観光で訪問',
      );

      final dto2 = PinDto(
        id: 'id-124',
        pinId: 'pin-124',
        tripId: 'trip-457',
        groupId: 'group-790',
        latitude: 34.0522,
        longitude: -118.2437,
        locationName: 'ロサンゼルス',
        visitMemo: '仕事で訪問',
      );

      // Act & Assert
      expect(dto1, isNot(equals(dto2)));
      expect(dto1.hashCode, isNot(equals(dto2.hashCode)));
    });
  });
}
