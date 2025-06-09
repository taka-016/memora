import 'package:memora/domain/repositories/pin_repository.dart';

class SavePinUseCase {
  final PinRepository pinRepository;
  SavePinUseCase(this.pinRepository);

  Future<void> execute(String pinId, double latitude, double longitude) async {
    await pinRepository.savePin(pinId, latitude, longitude);
  }
}
