import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/trip/create_trip_entry_usecase.dart';
import 'package:memora/application/usecases/trip/delete_trip_entry_usecase.dart';
import 'package:memora/application/usecases/trip/get_itinerary_items_by_trip_id_usecase.dart';
import 'package:memora/application/usecases/trip/get_locations_by_group_id_usecase.dart';
import 'package:memora/application/usecases/trip/get_tasks_by_trip_id_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';
import 'package:memora/application/usecases/trip/update_trip_entry_usecase.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final createTripEntryUsecaseProvider = Provider<CreateTripEntryUsecase>((ref) {
  return CreateTripEntryUsecase(ref.watch(tripEntryRepositoryProvider));
});

final deleteTripEntryUsecaseProvider = Provider<DeleteTripEntryUsecase>((ref) {
  return DeleteTripEntryUsecase(ref.watch(tripEntryRepositoryProvider));
});

final getItineraryItemsByTripIdUsecaseProvider =
    Provider<GetItineraryItemsByTripIdUsecase>((ref) {
      return GetItineraryItemsByTripIdUsecase(
        ref.watch(itineraryItemQueryServiceProvider),
      );
    });

final getLocationsByGroupIdUsecaseProvider =
    Provider<GetLocationsByGroupIdUsecase>((ref) {
      ref.watch(appCapabilitiesProvider).requireAvailable(AppFeature.maps);
      return GetLocationsByGroupIdUsecase(
        ref.watch(locationQueryServiceProvider),
      );
    });

final getTasksByTripIdUsecaseProvider = Provider<GetTasksByTripIdUsecase>((
  ref,
) {
  return GetTasksByTripIdUsecase(ref.watch(taskQueryServiceProvider));
});

final getTripEntriesUsecaseProvider = Provider<GetTripEntriesUsecase>((ref) {
  return GetTripEntriesUsecase(ref.watch(tripEntryQueryServiceProvider));
});

final getMapTripEntriesUsecaseProvider = Provider<GetTripEntriesUsecase>((ref) {
  ref.watch(appCapabilitiesProvider).requireAvailable(AppFeature.maps);
  return GetTripEntriesUsecase(ref.watch(mapTripEntryQueryServiceProvider));
});

final getTripEntryByIdUsecaseProvider = Provider<GetTripEntryByIdUsecase>((
  ref,
) {
  return GetTripEntryByIdUsecase(ref.watch(tripEntryQueryServiceProvider));
});

final updateTripEntryUsecaseProvider = Provider<UpdateTripEntryUsecase>((ref) {
  return UpdateTripEntryUsecase(ref.watch(tripEntryRepositoryProvider));
});
