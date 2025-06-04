import 'package:flutter_verification/domain/repositories/pin_repository.dart';

class DeletePinUseCase {
  final PinRepository pinRepository;
  DeletePinUseCase(this.pinRepository);

  Future<void> execute(String markerId) async {
    await pinRepository.deletePin(markerId);
  }
}
