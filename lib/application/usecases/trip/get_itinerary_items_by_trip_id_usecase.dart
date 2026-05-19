import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getItineraryItemsByTripIdUsecaseProvider =
    Provider<GetItineraryItemsByTripIdUsecase>((ref) {
      return GetItineraryItemsByTripIdUsecase(
        ref.watch(itineraryItemQueryServiceProvider),
      );
    });

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
