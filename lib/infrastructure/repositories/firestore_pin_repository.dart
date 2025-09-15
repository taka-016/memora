import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/pin_repository.dart';
import '../../domain/entities/pin.dart';
import '../../domain/value_objects/order_by.dart';
import '../mappers/firestore_pin_mapper.dart';
import '../../core/app_logger.dart';

class FirestorePinRepository implements PinRepository {
  final FirebaseFirestore _firestore;

  FirestorePinRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> savePin(Pin pin) async {
    await _firestore
        .collection('pins')
        .add(FirestorePinMapper.toFirestore(pin));
  }

  @override
  Future<List<Pin>> getPins() async {
    try {
      final snapshot = await _firestore.collection('pins').get();
      return snapshot.docs
          .map((doc) => FirestorePinMapper.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      logger.e(
        'FirestorePinRepository.getPins: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<void> deletePin(String pinId) async {
    final query = await _firestore
        .collection('pins')
        .where('pinId', isEqualTo: pinId)
        .get();
    for (final doc in query.docs) {
      await _firestore.collection('pins').doc(doc.id).delete();
    }
  }

  @override
  Future<List<Pin>> getPinsByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('pins')
          .where('tripId', isEqualTo: tripId);

      // ソート条件が指定されている場合のみ適用
      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => FirestorePinMapper.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      logger.e(
        'FirestorePinRepository.getPinsByTripId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<void> savePinWithTrip(Pin pin) async {
    await _firestore
        .collection('pins')
        .add(FirestorePinMapper.toFirestore(pin));
  }

  @override
  Future<void> deletePinsByTripId(String tripId) async {
    final query = await _firestore
        .collection('pins')
        .where('tripId', isEqualTo: tripId)
        .get();
    for (final doc in query.docs) {
      await _firestore.collection('pins').doc(doc.id).delete();
    }
  }
}
