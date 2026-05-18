import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_itinerary_item_mapper.dart';

class FirestoreItineraryItemQueryService implements ItineraryItemQueryService {
  FirestoreItineraryItemQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<ItineraryItemDto>> getItineraryItemsByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('itinerary_items')
          .where('tripId', isEqualTo: tripId);

      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(FirestoreItineraryItemMapper.fromFirestore)
          .toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreItineraryItemQueryService.getItineraryItemsByTripId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }
}
