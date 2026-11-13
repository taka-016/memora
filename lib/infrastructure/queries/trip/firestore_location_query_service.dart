import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/queries/trip/location_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_location_mapper.dart';

class FirestoreLocationQueryService implements LocationQueryService {
  FirestoreLocationQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<LocationDto>> getLocationsByGroupId(String groupId) async {
    try {
      final parents = await _firestore.collection('trip_entries').where('groupId', isEqualTo: groupId).get();
      final result = <LocationDto>[];
      for (final parent in parents.docs) {
        final snapshot = await _firestore.collection('locations').where('groupId', isEqualTo: groupId).where('tripId', isEqualTo: parent.id).get();
        result.addAll(snapshot.docs.map(FirestoreLocationMapper.fromFirestore));
      }
      return result;
    } catch (e, stack) {
      logger.e(
        'FirestoreLocationQueryService.getLocationsByGroupId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
