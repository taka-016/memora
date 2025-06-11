import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/pin.dart';

void main() {
  group('Pin', () {
    test('インスタンス生成が正しく行われる', () {
      final pin = Pin(
        id: 'id001',
        pinId: 'pin001',
        latitude: 35.0,
        longitude: 139.0,
      );
      expect(pin.id, 'id001');
      expect(pin.pinId, 'pin001');
      expect(pin.latitude, 35.0);
      expect(pin.longitude, 139.0);
    });
  });
}
