import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/repositories/trip/location_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final deleteLocationUsecaseProvider = Provider<DeleteLocationUsecase>((ref) {
  return DeleteLocationUsecase(ref.watch(locationRepositoryProvider));
});

class DeleteLocationUsecase {
  DeleteLocationUsecase(this._locationRepository);

  final LocationRepository _locationRepository;

  Future<void> execute(String locationId) async {
    await _locationRepository.deleteLocation(locationId);
  }
}
