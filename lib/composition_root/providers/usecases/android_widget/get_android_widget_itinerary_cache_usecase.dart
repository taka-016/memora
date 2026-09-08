import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';

final getAndroidWidgetItineraryCacheUsecaseProvider =
    Provider<GetAndroidWidgetItineraryCacheUsecase>((ref) {
      return GetAndroidWidgetItineraryCacheUsecase(
        tripEntryQueryService: ref.watch(tripEntryQueryServiceProvider),
        itineraryItemQueryService: ref.watch(itineraryItemQueryServiceProvider),
        clock: ref.watch(appClockProvider),
      );
    });
