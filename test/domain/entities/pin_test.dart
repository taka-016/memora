import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/pin.dart';

void main() {
  group('Pin', () {
    test('インスタンス生成が正しく行われる', () {
      final pin = Pin(
        id: 'id001',
        pinId: 'pin001',
        tripId: 'trip001',
        latitude: 35.0,
        longitude: 139.0,
        visitStartDate: DateTime(2025, 6, 1),
        visitEndDate: DateTime(2025, 6, 2),
        visitMemo: 'テストメモ',
      );
      expect(pin.id, 'id001');
      expect(pin.pinId, 'pin001');
      expect(pin.tripId, 'trip001');
      expect(pin.latitude, 35.0);
      expect(pin.longitude, 139.0);
      expect(pin.visitStartDate, DateTime(2025, 6, 1));
      expect(pin.visitEndDate, DateTime(2025, 6, 2));
      expect(pin.visitMemo, 'テストメモ');
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final pin = Pin(id: 'id001', pinId: 'pin001', latitude: 35.0, longitude: 139.0);
      expect(pin.id, 'id001');
      expect(pin.pinId, 'pin001');
      expect(pin.tripId, null);
      expect(pin.latitude, 35.0);
      expect(pin.longitude, 139.0);
      expect(pin.visitStartDate, null);
      expect(pin.visitEndDate, null);
      expect(pin.visitMemo, null);
    });
  });
}
