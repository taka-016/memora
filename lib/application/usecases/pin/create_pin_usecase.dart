import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/application/mappers/pin_mapper.dart';
import 'package:memora/domain/repositories/pin_repository.dart';

class CreatePinUseCase {
  final PinRepository _pinRepository;
  CreatePinUseCase(this._pinRepository);

  Future<void> execute(PinDto pinDto) async {
    final pin = PinMapper.toEntity(pinDto);
    await _pinRepository.savePin(pin);
  }
}
