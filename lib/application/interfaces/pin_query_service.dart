import 'package:memora/application/dtos/pin/pin_dto.dart';

abstract class PinQueryService {
  Future<List<PinDto>> getPinsByMemberId(String memberId);
}
