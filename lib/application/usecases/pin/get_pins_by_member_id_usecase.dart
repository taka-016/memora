import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/application/interfaces/pin_query_service.dart';

class GetPinsByMemberIdUsecase {
  final PinQueryService _pinQueryService;

  GetPinsByMemberIdUsecase(this._pinQueryService);

  Future<List<PinDto>> execute(String memberId) async {
    return await _pinQueryService.getPinsByMemberId(memberId);
  }
}
