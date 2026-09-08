import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/queries/trip/location_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/trip/get_locations_by_group_id_usecase.dart';

final getLocationsByGroupIdUsecaseProvider =
    Provider<GetLocationsByGroupIdUsecase>((ref) {
      return GetLocationsByGroupIdUsecase(
        ref.watch(locationQueryServiceProvider),
      );
    });
