import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/repositories/pin_repository.dart';

class GetPinsUseCase {
  final PinRepository _pinRepository;

  GetPinsUseCase(this._pinRepository);

  Future<List<Pin>> execute() async {
    return await _pinRepository.getPins();
  }
}
