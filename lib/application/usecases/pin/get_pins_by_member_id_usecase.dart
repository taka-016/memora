import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/application/interfaces/pin_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getPinsByMemberIdUsecaseProvider = Provider<GetPinsByMemberIdUsecase>((
  ref,
) {
  return GetPinsByMemberIdUsecase(ref.watch(pinQueryServiceProvider));
});

class GetPinsByMemberIdUsecase {
  final PinQueryService _pinQueryService;

  GetPinsByMemberIdUsecase(this._pinQueryService);

  Future<List<PinDto>> execute(String memberId) async {
    return await _pinQueryService.getPinsByMemberId(memberId);
  }
}
