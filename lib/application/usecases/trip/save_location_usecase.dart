import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/mappers/trip/location_mapper.dart';
import 'package:memora/domain/repositories/trip/location_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final saveLocationUsecaseProvider = Provider<SaveLocationUsecase>((ref) {
  return SaveLocationUsecase(ref.watch(locationRepositoryProvider));
});

class SaveLocationUsecase {
  SaveLocationUsecase(this._locationRepository);

  final LocationRepository _locationRepository;

  Future<void> execute(LocationDto location) async {
    await _locationRepository.saveLocation(LocationMapper.toEntity(location));
  }
}
