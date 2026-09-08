import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/infrastructure/factories/current_location_service_factory.dart';
import 'package:memora/application/usecases/location/get_current_location_usecase.dart';

final getCurrentLocationUsecaseProvider = Provider<GetCurrentLocationUsecase>((
  ref,
) {
  return GetCurrentLocationUsecase(ref.watch(currentLocationServiceProvider));
});
