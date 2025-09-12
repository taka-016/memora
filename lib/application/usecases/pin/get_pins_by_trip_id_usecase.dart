import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/application/mappers/pin_mapper.dart';
import 'package:memora/domain/repositories/pin_repository.dart';
import 'package:memora/domain/value_objects/order_by.dart';

class GetPinsByTripIdUseCase {
  final PinRepository _pinRepository;

  GetPinsByTripIdUseCase(this._pinRepository);

  Future<List<PinDto>> execute(String tripId) async {
    final pins = await _pinRepository.getPinsByTripId(
      tripId,
      orderBy: [const OrderBy('visitStartDate', descending: false)],
    );
    return PinMapper.toDtoList(pins);
  }
}
