import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/application/mappers/pin_mapper.dart';
import 'package:memora/domain/repositories/pin_repository.dart';

class GetPinsUseCase {
  final PinRepository _pinRepository;

  GetPinsUseCase(this._pinRepository);

  Future<List<PinDto>> execute() async {
    final pins = await _pinRepository.getPins();
    return PinMapper.toDtoList(pins);
  }
}
