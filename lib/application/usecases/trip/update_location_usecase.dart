import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/mappers/trip/location_mapper.dart';
import 'package:memora/domain/repositories/trip/location_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final updateLocationUsecaseProvider = Provider<UpdateLocationUsecase>((ref) {
  return UpdateLocationUsecase(ref.watch(locationRepositoryProvider));
});

class UpdateLocationUsecase {
  UpdateLocationUsecase(this._locationRepository);

  final LocationRepository _locationRepository;

  Future<void> execute(LocationDto location) async {
    await _locationRepository.updateLocation(LocationMapper.toEntity(location));
  }
}
