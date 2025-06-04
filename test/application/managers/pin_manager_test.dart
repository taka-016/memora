import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_verification/application/managers/pin_manager.dart';
import 'package:flutter_verification/domain/repositories/pin_repository.dart';
import 'package:flutter_verification/domain/entities/pin.dart';

class MockPinRepository implements PinRepository {
  List<Pin> pins = [
    Pin(id: '1', markerId: '1', latitude: 10, longitude: 10),
    Pin(id: '2', markerId: '2', latitude: 20, longitude: 20),
  ];

  @override
  Future<List<Pin>> getPins() async {
    return pins
        .asMap()
        .entries
        .map(
          (e) => Pin(
            id: e.value.id,
            markerId: e.value.markerId,
            latitude: e.value.latitude,
            longitude: e.value.longitude,
          ),
        )
        .toList();
  }

  @override
  Future<void> savePin(
    String markerId,
    double latitude,
    double longitude,
  ) async {
    pins.add(
      Pin(
        id: markerId,
        markerId: markerId,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  @override
  Future<void> deletePin(String markerId) async {
    pins.removeWhere((pin) => pin.markerId == markerId);
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
      final markerId = MarkerId('test-marker-id');
      final position = const LatLng(35.0, 139.0);
      await pinManager.addPin(position, markerId, null);
      expect(pinManager.markers.any((m) => m.markerId == markerId), isTrue);
    });

    test('ピンを削除できる', () async {
      final markerId = MarkerId('test-marker-id');
      final position = const LatLng(35.0, 139.0);
      await pinManager.addPin(position, markerId, null);
      await mockRepo.savePin(
        markerId.value,
        position.latitude,
        position.longitude,
      );
      await pinManager.removePin(markerId);
      expect(pinManager.markers.any((m) => m.markerId == markerId), isFalse);
      expect(mockRepo.pins.any((p) => p.markerId == markerId.value), isFalse);
    });

    test('初期ピンを読み込める', () async {
      final pins = [
        Pin(id: '1', markerId: '1', latitude: 35.1, longitude: 139.1),
        Pin(id: '2', markerId: '2', latitude: 35.2, longitude: 139.2),
      ];
      await pinManager.loadInitialPins(pins, null);
      expect(pinManager.markers.length, pins.length);
    });

    test('永続化層からピンを読み込める', () async {
      await pinManager.loadSavedPins();
      expect(pinManager.markers.length, mockRepo.pins.length);
      expect(pinManager.markers[0].markerId.value, mockRepo.pins[0].markerId);
    });
  });
}
