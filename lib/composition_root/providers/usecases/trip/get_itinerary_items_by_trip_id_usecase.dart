import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/trip/get_itinerary_items_by_trip_id_usecase.dart';

final getItineraryItemsByTripIdUsecaseProvider =
    Provider<GetItineraryItemsByTripIdUsecase>((ref) {
      return GetItineraryItemsByTripIdUsecase(
        ref.watch(itineraryItemQueryServiceProvider),
      );
    });
