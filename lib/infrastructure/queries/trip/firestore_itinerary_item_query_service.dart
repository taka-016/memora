import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_itinerary_item_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_location_mapper.dart';

class FirestoreItineraryItemQueryService implements ItineraryItemQueryService {
  FirestoreItineraryItemQueryService({
    FirebaseFirestore? firestore,
    this._rethrowOnError = false,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final bool _rethrowOnError;

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
      final items = <ItineraryItemDto>[];
      for (final doc in snapshot.docs) {
        final location = await _getLocation(doc.data()['locationId']);
        items.add(
          FirestoreItineraryItemMapper.fromFirestore(doc, location: location),
        );
      }
      return items;
    } catch (e, stack) {
      logger.e(
        'FirestoreItineraryItemQueryService.getItineraryItemsByTripId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (_rethrowOnError) {
        rethrow;
      }
      return [];
    }
  }

  Future<LocationDto?> _getLocation(dynamic locationId) async {
    if (locationId is! String || locationId.isEmpty) {
      return null;
    }

    final locationDoc = await _firestore
        .collection('locations')
        .doc(locationId)
        .get();
    if (!locationDoc.exists) {
      return null;
    }
    return FirestoreLocationMapper.fromFirestore(locationDoc);
  }
}
