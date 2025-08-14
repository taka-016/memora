import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/repositories/pin_repository.dart';

class LoadPinsUseCase {
  final PinRepository _pinRepository;

  LoadPinsUseCase(this._pinRepository);

  Future<List<Pin>> execute([String? tripId]) async {
    if (tripId != null) {
      return await _pinRepository.getPinsByTripId(tripId);
    }
    return await _pinRepository.getPins();
  }
}
