import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_verification/application/managers/pin_manager.dart';

class MockPinRepository {
  List<LatLng> pins = [const LatLng(10, 10), const LatLng(20, 20)];
  Future<List<LatLng>> loadPins() async => pins;
}

typedef PinTapCallback = void Function(LatLng position);

void main() {
  group('PinManager', () {
    late PinManager pinManager;

    setUp(() {
      pinManager = PinManager();
    });

    test('ピンを追加できる', () async {
      final position = const LatLng(35.0, 139.0);
      await pinManager.addPin(position, null);
      expect(pinManager.markers.any((m) => m.position == position), isTrue);
    });

    test('ピンを削除できる', () async {
      final position = const LatLng(35.0, 139.0);
      await pinManager.addPin(position, null);
      final marker = pinManager.markers.firstWhere(
        (m) => m.position == position,
      );
      pinManager.removePin(marker.markerId);
      expect(pinManager.markers.any((m) => m.position == position), isFalse);
    });

    test('初期ピンを読み込める', () async {
      final pins = [const LatLng(35.1, 139.1), const LatLng(35.2, 139.2)];
      await pinManager.loadInitialPins(pins, null);
      expect(pinManager.markers.length, pins.length);
    });

    test('永続化層からピンを読み込める', () async {
      final mockRepo = MockPinRepository();
      await pinManager.loadSavedPins(mockRepo);
      expect(pinManager.markers.length, mockRepo.pins.length);
      expect(pinManager.markers[0].position, mockRepo.pins[0]);
    });
  });
}
