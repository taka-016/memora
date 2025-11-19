import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/route_dto.dart';
import 'package:memora/application/mappers/trip/route_mapper.dart';
import 'package:memora/application/queries/trip/route_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/value_objects/order_by.dart';

class FirestoreRouteQueryService implements RouteQueryService {
  FirestoreRouteQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<RouteDto>> getRoutesByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('routes')
          .where('tripId', isEqualTo: tripId);

      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs.map(RouteMapper.fromFirestore).toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreRouteQueryService.getRoutesByTripId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }
}
