import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/entities/pin_detail.dart';

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
        details: [
          PinDetail(
            pinId: 'pin001',
            name: '朝食',
            startDate: DateTime(2025, 6, 1, 8, 0),
            endDate: DateTime(2025, 6, 1, 9, 0),
          ),
        ],
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
      expect(pin.details, hasLength(1));
      expect(pin.details.first.name, '朝食');
    });

    test('訪問終了日時が開始日時より前の場合は例外が発生する', () {
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
        throwsArgumentError,
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
        details: [
          PinDetail(
            pinId: 'pin001',
            name: '夜景鑑賞',
            startDate: DateTime(2025, 6, 1, 20, 0),
            endDate: DateTime(2025, 6, 1, 22, 0),
          ),
        ],
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
      expect(updatedPin.details, hasLength(1));
      expect(updatedPin.details.first.name, '夜景鑑賞');
    });

    test('訪問期間外の詳細予定が含まれる場合は例外が発生する', () {
      expect(
        () => Pin(
          id: 'id001',
          pinId: 'pin001',
          tripId: 'trip001',
          groupId: 'group001',
          latitude: 35.0,
          longitude: 139.0,
          visitStartDate: DateTime(2025, 6, 1, 8, 0),
          visitEndDate: DateTime(2025, 6, 1, 20, 0),
          details: [
            PinDetail(
              pinId: 'pin001',
              startDate: DateTime(2025, 6, 1, 7, 0),
              endDate: DateTime(2025, 6, 1, 9, 0),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('訪問日時が未設定の場合に詳細予定を含めると例外が発生する', () {
      expect(
        () => Pin(
          id: 'id001',
          pinId: 'pin001',
          tripId: 'trip001',
          groupId: 'group001',
          latitude: 35.0,
          longitude: 139.0,
          details: [
            PinDetail(pinId: 'pin001', startDate: DateTime(2025, 6, 1, 10, 0)),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
