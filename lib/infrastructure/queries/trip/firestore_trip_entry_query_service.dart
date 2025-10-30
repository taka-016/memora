import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/pin_detail_mapper.dart';
import 'package:memora/application/mappers/trip/pin_mapper.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/value_objects/order_by.dart';

class FirestoreTripEntryQueryService implements TripEntryQueryService {
  final FirebaseFirestore _firestore;

  FirestoreTripEntryQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<TripEntryDto?> getTripEntryById(
    String tripId, {
    List<OrderBy>? pinsOrderBy,
    List<OrderBy>? pinDetailsOrderBy,
  }) async {
    try {
      final doc = await _firestore.collection('trip_entries').doc(tripId).get();
      if (!doc.exists) {
        return null;
      }

      Query<Map<String, dynamic>> pinsQuery = _firestore
          .collection('pins')
          .where('tripId', isEqualTo: tripId);

      if (pinsOrderBy != null && pinsOrderBy.isNotEmpty) {
        for (final order in pinsOrderBy) {
          pinsQuery = pinsQuery.orderBy(
            order.field,
            descending: order.descending,
          );
        }
      }

      final pinsSnapshot = await pinsQuery.get();
      final pins = <PinDto>[];

      for (final pinDoc in pinsSnapshot.docs) {
        final pinId = pinDoc.data()['pinId'] as String? ?? '';
        Query<Map<String, dynamic>> pinDetailsQuery = _firestore
            .collection('pin_details')
            .where('pinId', isEqualTo: pinId);

        if (pinDetailsOrderBy != null && pinDetailsOrderBy.isNotEmpty) {
          for (final order in pinDetailsOrderBy) {
            pinDetailsQuery = pinDetailsQuery.orderBy(
              order.field,
              descending: order.descending,
            );
          }
        }

        final pinDetailsSnapshot = await pinDetailsQuery.get();
        final pinDetails = pinDetailsSnapshot.docs
            .map((detailDoc) => PinDetailMapper.fromFirestore(detailDoc))
            .toList();

        final PinDto pin = PinMapper.fromFirestore(pinDoc, details: pinDetails);
        pins.add(pin);
      }

      return TripEntryMapper.fromFirestore(doc, pins: pins);
    } catch (e, stack) {
      logger.e(
        'FirestoreTripEntryQueryService.getTripEntryById: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  }) async {
    try {
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year + 1, 1, 1);

      Query<Map<String, dynamic>> query = _firestore
          .collection('trip_entries')
          .where('groupId', isEqualTo: groupId)
          .where(
            'tripStartDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
          )
          .where('tripStartDate', isLessThan: Timestamp.fromDate(endOfYear));

      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => TripEntryMapper.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreTripEntryQueryService.getTripEntriesByGroupIdAndYear: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }
}
