import 'package:memora/domain/repositories/pin_repository.dart';

class DeletePinsByTripIdUseCase {
  final PinRepository _pinRepository;

  DeletePinsByTripIdUseCase(this._pinRepository);

  Future<void> execute(String tripId) async {
    return await _pinRepository.deletePinsByTripId(tripId);
  }
}
