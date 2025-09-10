import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/repositories/pin_repository.dart';
import 'package:memora/domain/value_objects/order_by.dart';

class GetPinsByTripIdUseCase {
  final PinRepository _pinRepository;

  GetPinsByTripIdUseCase(this._pinRepository);

  Future<List<Pin>> execute(String tripId) async {
    return await _pinRepository.getPinsByTripId(
      tripId,
      orderBy: [const OrderBy('visitStartDate', descending: false)],
    );
  }
}
