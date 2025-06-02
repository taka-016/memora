import 'package:flutter_verification/domain/repositories/pin_repository.dart';

class DeletePinUseCase {
  final PinRepository pinRepository;
  DeletePinUseCase(this.pinRepository);

  Future<void> execute(double latitude, double longitude) async {
    await pinRepository.deletePin(latitude, longitude);
  }
}
