import 'package:memora/domain/repositories/trip/location_repository.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';

abstract class TripWriteUnitOfWork {
  Future<T> run<T>(
    Future<T> Function(TripWriteRepositories repositories) action,
  );
}

abstract class TripWriteRepositories {
  TripEntryRepository get tripEntryRepository;
  LocationRepository get locationRepository;
}
