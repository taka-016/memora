import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/nearby_location_service_factory.dart';
import 'package:memora/application/usecases/location/get_nearby_location_name_usecase.dart';

final getNearbyLocationNameUsecaseProvider =
    Provider<GetNearbyLocationNameUsecase>((ref) {
      return GetNearbyLocationNameUsecase(
        ref.watch(nearbyLocationServiceProvider),
      );
    });
