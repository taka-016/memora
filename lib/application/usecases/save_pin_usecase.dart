import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_verification/domain/repositories/pin_repository.dart';

class SavePinUseCase {
  final PinRepository pinRepository;
  SavePinUseCase(this.pinRepository);

  Future<void> execute(LatLng position) async {
    await pinRepository.savePin(position);
  }
}
