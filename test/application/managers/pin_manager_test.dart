import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_verification/application/managers/pin_manager.dart';
import 'package:flutter_verification/domain/repositories/pin_repository.dart';
import 'package:flutter_verification/application/usecases/load_pins_usecase.dart';
import 'package:flutter_verification/application/usecases/save_pin_usecase.dart';
import 'package:flutter_verification/application/usecases/delete_pin_usecase.dart';

@GenerateMocks([
  PinRepository,
  LoadPinsUseCase,
  SavePinUseCase,
  DeletePinUseCase,
])
import 'pin_manager_test.mocks.dart';

void main() {
  group('PinManager', () {
    late PinManager pinManager;
    late MockPinRepository mockRepo;
    late MockLoadPinsUseCase mockLoadPinsUseCase;
    late MockSavePinUseCase mockSavePinUseCase;
    late MockDeletePinUseCase mockDeletePinUseCase;

    setUp(() {
      mockRepo = MockPinRepository();
      mockLoadPinsUseCase = MockLoadPinsUseCase();
      mockSavePinUseCase = MockSavePinUseCase();
      mockDeletePinUseCase = MockDeletePinUseCase();
      pinManager = PinManager(pinRepository: mockRepo);
    });

    test('ピンを追加できる', () async {
      final position = const LatLng(35.0, 139.0);
      await pinManager.addPin(position, null);
      expect(pinManager.markers.any((m) => m.position == position), isTrue);
    });

    // test('ピンを削除できる', () async {
    //   final position = const LatLng(35.0, 139.0);
    //   await pinManager.addPin(position, null);
    //   final marker = pinManager.markers.firstWhere(
    //     (m) => m.position == position,
    //   );
    //   // まずリポジトリにも追加
    //   await mockRepo.savePin(position);
    //   // removePinをawaitで呼び出せるようにする前提
    //   await pinManager.removePin(marker.markerId);
    //   expect(pinManager.markers.any((m) => m.position == position), isFalse);
    //   // リポジトリからも削除されていることを確認
    //   expect(mockRepo.pins.any((p) => p == position), isFalse);
    // });

    // test('初期ピンを読み込める', () async {
    //   final pins = [const LatLng(35.1, 139.1), const LatLng(35.2, 139.2)];
    //   await pinManager.loadInitialPins(pins, null);
    //   expect(pinManager.markers.length, pins.length);
    // });

    // test('永続化層からピンを読み込める', () async {
    //   await pinManager.loadSavedPins();
    //   expect(pinManager.markers.length, mockRepo.pins.length);
    //   expect(pinManager.markers[0].position, mockRepo.pins[0]);
    // });
  });
}
