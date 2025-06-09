import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/repositories/pin_repository.dart';

class LoadPinsUseCase {
  final PinRepository _pinRepository;

  LoadPinsUseCase(this._pinRepository);

  Future<List<Pin>> execute() async {
    return await _pinRepository.getPins();
  }
}
