import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';

class GetItineraryItemsByTripIdUsecase {
  GetItineraryItemsByTripIdUsecase(this._itineraryItemQueryService);

  final ItineraryItemQueryService _itineraryItemQueryService;

  Future<List<ItineraryItemDto>> execute(String tripId) async {
    return await _itineraryItemQueryService.getItineraryItemsByTripId(
      tripId,
      orderBy: const [
        OrderBy('startDateTime', descending: false),
        OrderBy('endDateTime', descending: false),
      ],
    );
  }
}
