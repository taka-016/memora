import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_verification/application/managers/pin_manager.dart';
import 'package:flutter_verification/domain/repositories/pin_repository.dart';
import 'package:flutter_verification/domain/entities/pin.dart';

class MockPinRepository implements PinRepository {
  List<LatLng> pins = [const LatLng(10, 10), const LatLng(20, 20)];

  @override
  Future<List<Pin>> getPins() async {
    return pins
        .asMap()
        .entries
        .map(
          (e) => Pin(
            id: e.key.toString(),
            latitude: e.value.latitude,
            longitude: e.value.longitude,
          ),
        )
        .toList();
  }

  @override
  Future<void> savePin(LatLng position) async {
    pins.add(position);
  }

  @override
  Future<void> deletePin(String pinId) async {
    // テスト用: pinsリストから該当IDのピンを削除
    final index = int.tryParse(pinId);
    if (index != null && index >= 0 && index < pins.length) {
      pins.removeAt(index);
    }
  }
}

typedef PinTapCallback = void Function(LatLng position);

void main() {
  group('PinManager', () {
    late PinManager pinManager;
    late MockPinRepository mockRepo;

    setUp(() {
      mockRepo = MockPinRepository();
      pinManager = PinManager(pinRepository: mockRepo);
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
      await pinManager.loadSavedPins();
      expect(pinManager.markers.length, mockRepo.pins.length);
      expect(pinManager.markers[0].position, mockRepo.pins[0]);
    });
  });
}
