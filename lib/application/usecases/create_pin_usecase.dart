import 'package:memora/domain/repositories/pin_repository.dart';
import 'package:memora/domain/entities/pin.dart';

class CreatePinUseCase {
  final PinRepository _pinRepository;
  CreatePinUseCase(this._pinRepository);

  Future<void> execute(Pin pin) async {
    await _pinRepository.savePin(pin);
  }
}
