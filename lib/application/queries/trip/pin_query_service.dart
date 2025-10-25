import 'package:memora/application/dtos/trip/pin_dto.dart';

abstract class PinQueryService {
  Future<List<PinDto>> getPinsByMemberId(String memberId);
}
