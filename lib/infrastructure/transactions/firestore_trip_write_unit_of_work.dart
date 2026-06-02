import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/transactions/trip_write_unit_of_work.dart';
import 'package:memora/domain/repositories/trip/location_repository.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/repositories/trip/firestore_location_repository.dart';
import 'package:memora/infrastructure/repositories/trip/firestore_trip_entry_repository.dart';

class FirestoreTripWriteUnitOfWork implements TripWriteUnitOfWork {
  FirestoreTripWriteUnitOfWork({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<T> run<T>(
    Future<T> Function(TripWriteRepositories repositories) action,
  ) {
    return _firestore.runTransaction<T>((transaction) async {
      final repositories = _FirestoreTripWriteRepositories(
        tripEntryRepository: FirestoreTripEntryRepository(
          firestore: _firestore,
        ),
        locationRepository: FirestoreLocationRepository(firestore: _firestore),
      );
      return action(repositories);
    });
  }
}

class _FirestoreTripWriteRepositories implements TripWriteRepositories {
  const _FirestoreTripWriteRepositories({
    required this.tripEntryRepository,
    required this.locationRepository,
  });

  @override
  final TripEntryRepository tripEntryRepository;

  @override
  final LocationRepository locationRepository;
}
