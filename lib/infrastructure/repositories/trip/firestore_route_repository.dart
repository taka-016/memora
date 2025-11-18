import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/trip/route.dart';
import 'package:memora/domain/repositories/trip/route_repository.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_route_mapper.dart';

class FirestoreRouteRepository implements RouteRepository {
  FirestoreRouteRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _routesCollection =>
      _firestore.collection('routes');

  @override
  Future<void> saveRoutes(String tripId, List<Route> routes) async {
    if (routes.isEmpty) {
      return;
    }
    final batch = _firestore.batch();
    for (final route in routes) {
      final docRef = _routesCollection.doc(route.id);
      batch.set(docRef, FirestoreRouteMapper.toFirestore(route));
    }
    await batch.commit();
  }

  @override
  Future<void> updateRoutes(String tripId, List<Route> routes) async {
    final batch = _firestore.batch();
    final snapshot = await _routesCollection
        .where('tripId', isEqualTo: tripId)
        .get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    for (final route in routes) {
      final docRef = _routesCollection.doc(route.id);
      batch.set(docRef, FirestoreRouteMapper.toFirestore(route));
    }
    await batch.commit();
  }

  @override
  Future<void> deleteRoutes(String tripId) async {
    final batch = _firestore.batch();
    final snapshot = await _routesCollection
        .where('tripId', isEqualTo: tripId)
        .get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> deleteRoutesByPinId(String pinId) async {
    final batch = _firestore.batch();
    final refs = <DocumentReference<Map<String, dynamic>>>{};

    final departureSnapshot = await _routesCollection
        .where('departurePinId', isEqualTo: pinId)
        .get();
    for (final doc in departureSnapshot.docs) {
      refs.add(doc.reference);
    }

    final arrivalSnapshot = await _routesCollection
        .where('arrivalPinId', isEqualTo: pinId)
        .get();
    for (final doc in arrivalSnapshot.docs) {
      refs.add(doc.reference);
    }

    if (refs.isEmpty) {
      return;
    }

    for (final ref in refs) {
      batch.delete(ref);
    }
    await batch.commit();
  }
}
