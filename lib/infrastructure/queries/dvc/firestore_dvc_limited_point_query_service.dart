import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_limited_point_mapper.dart';
import 'package:memora/application/queries/dvc/dvc_limited_point_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/value_objects/order_by.dart';

class FirestoreDvcLimitedPointQueryService
    implements DvcLimitedPointQueryService {
  FirestoreDvcLimitedPointQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<DvcLimitedPointDto>> getDvcLimitedPointsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('dvc_limited_points')
          .where('groupId', isEqualTo: groupId);

      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs.map(DvcLimitedPointMapper.fromFirestore).toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreDvcLimitedPointQueryService.getDvcLimitedPointsByGroupId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }
}
