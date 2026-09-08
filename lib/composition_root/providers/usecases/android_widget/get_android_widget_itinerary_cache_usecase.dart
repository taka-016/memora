import 'package:flutter_riverpod/flutter_riverpod.dart';
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
