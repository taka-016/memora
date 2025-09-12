import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/application/mappers/pin_mapper.dart';
import 'package:memora/domain/repositories/pin_repository.dart';

class CreatePinUseCase {
  final PinRepository _pinRepository;
  CreatePinUseCase(this._pinRepository);

  Future<void> execute(PinDto pinDto, {String id = ''}) async {
    final pin = PinMapper.toEntity(pinDto, id: id);
    await _pinRepository.savePin(pin);
  }
}
