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
      final snapshot = await _firestore
          .collection('locations')
          .where('groupId', isEqualTo: groupId)
          .get();
      return snapshot.docs.map(FirestoreLocationMapper.fromFirestore).toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreLocationQueryService.getLocationsByGroupId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }
}
