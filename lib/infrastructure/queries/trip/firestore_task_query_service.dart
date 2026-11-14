import 'package:memora/infrastructure/services/firestore_parent_group_id.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/queries/trip/task_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_task_mapper.dart';

class FirestoreTaskQueryService implements TaskQueryService {
  FirestoreTaskQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<TaskDto>> getTasksByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  }) async {
    try {
      final groupId = await firestoreParentGroupId(
        _firestore,
        'trip_entries',
        tripId,
      );
      if (groupId == null) return [];
      Query<Map<String, dynamic>> query = _firestore
          .collection('tasks')
          .where('tripId', isEqualTo: tripId)
          .where('groupId', isEqualTo: groupId);

      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs.map(FirestoreTaskMapper.fromFirestore).toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreTaskQueryService.getTasksByTripId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
