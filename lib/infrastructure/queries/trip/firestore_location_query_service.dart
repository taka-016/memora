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
  Future<List<LocationDto>> getLocationsByTripId(String tripId) async {
    return _getLocationsByField('tripId', tripId);
  }

  @override
  Future<List<LocationDto>> getLocationsByGroupId(String groupId) async {
    return _getLocationsByField('groupId', groupId);
  }

  Future<List<LocationDto>> _getLocationsByField(
    String field,
    String value,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('locations')
          .where(field, isEqualTo: value)
          .get();
      return snapshot.docs.map(FirestoreLocationMapper.fromFirestore).toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreLocationQueryService._getLocationsByField: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }
}
