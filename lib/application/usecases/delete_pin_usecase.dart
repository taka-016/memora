import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_verification/domain/repositories/pin_repository.dart';

class DeletePinUseCase {
  final PinRepository pinRepository;
  DeletePinUseCase(this.pinRepository);

  Future<void> execute(String pinId) async {
    await pinRepository.deletePin(pinId);
  }
}
