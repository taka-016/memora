import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/pin.dart';

void main() {
  group('Pin', () {
    test('インスタンス生成が正しく行われる', () {
      final pin = Pin(
        id: 'id001',
        pinId: 'pin001',
        tripId: 'trip001',
        groupId: 'group001',
        latitude: 35.0,
        longitude: 139.0,
        locationName: '東京駅',
        visitStartDate: DateTime(2025, 6, 1),
        visitEndDate: DateTime(2025, 6, 2),
        visitMemo: 'テストメモ',
      );
      expect(pin.id, 'id001');
      expect(pin.pinId, 'pin001');
      expect(pin.tripId, 'trip001');
      expect(pin.groupId, 'group001');
      expect(pin.latitude, 35.0);
      expect(pin.longitude, 139.0);
      expect(pin.locationName, '東京駅');
      expect(pin.visitStartDate, DateTime(2025, 6, 1));
      expect(pin.visitEndDate, DateTime(2025, 6, 2));
      expect(pin.visitMemo, 'テストメモ');
    });

    test('訪問終了日時が開始日時より前の場合はassertが発生する', () {
      expect(
        () => Pin(
          id: 'id001',
          pinId: 'pin001',
          tripId: 'trip001',
          groupId: 'group001',
          latitude: 35.0,
          longitude: 139.0,
          visitStartDate: DateTime(2025, 6, 2),
          visitEndDate: DateTime(2025, 6, 1),
        ),
        throwsAssertionError,
      );
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final pin = Pin(
        id: 'id001',
        pinId: 'pin001',
        tripId: 'trip001',
        groupId: 'group001',
        latitude: 35.0,
        longitude: 139.0,
      );
      expect(pin.id, 'id001');
      expect(pin.pinId, 'pin001');
      expect(pin.tripId, 'trip001');
      expect(pin.groupId, 'group001');
      expect(pin.latitude, 35.0);
      expect(pin.longitude, 139.0);
      expect(pin.locationName, null);
      expect(pin.visitStartDate, null);
      expect(pin.visitEndDate, null);
      expect(pin.visitMemo, null);
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final pin1 = Pin(
        id: 'id001',
        pinId: 'pin001',
        tripId: 'trip001',
        groupId: 'group001',
        latitude: 35.0,
        longitude: 139.0,
        locationName: '東京駅',
        visitStartDate: DateTime(2025, 6, 1),
        visitEndDate: DateTime(2025, 6, 2),
        visitMemo: 'テストメモ',
      );
      final pin2 = Pin(
        id: 'id001',
        pinId: 'pin001',
        tripId: 'trip001',
        groupId: 'group001',
        latitude: 35.0,
        longitude: 139.0,
        locationName: '東京駅',
        visitStartDate: DateTime(2025, 6, 1),
        visitEndDate: DateTime(2025, 6, 2),
        visitMemo: 'テストメモ',
      );
      expect(pin1, equals(pin2));
    });

    test('copyWithメソッドが正しく動作する', () {
      final pin = Pin(
        id: 'id001',
        pinId: 'pin001',
        tripId: 'trip001',
        groupId: 'group001',
        latitude: 35.0,
        longitude: 139.0,
        locationName: '東京駅',
        visitStartDate: DateTime(2025, 6, 1),
        visitEndDate: DateTime(2025, 6, 2),
        visitMemo: 'テストメモ',
      );
      final updatedPin = pin.copyWith(
        latitude: 36.0,
        locationName: '新宿駅',
        visitMemo: '新しいメモ',
      );
      expect(updatedPin.id, 'id001');
      expect(updatedPin.pinId, 'pin001');
      expect(updatedPin.tripId, 'trip001');
      expect(updatedPin.groupId, 'group001');
      expect(updatedPin.latitude, 36.0);
      expect(updatedPin.longitude, 139.0);
      expect(updatedPin.locationName, '新宿駅');
      expect(updatedPin.visitStartDate, DateTime(2025, 6, 1));
      expect(updatedPin.visitEndDate, DateTime(2025, 6, 2));
      expect(updatedPin.visitMemo, '新しいメモ');
    });
  });
}
