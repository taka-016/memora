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

  DocumentReference<Map<String, dynamic>> _docRefForRoute(Route route) {
    final docId = '${route.tripId}_${route.orderIndex}';
    return _routesCollection.doc(docId);
  }

  @override
  Future<void> saveRoute(Route route) async {
    final docRef = _docRefForRoute(route);
    await docRef.set(FirestoreRouteMapper.toFirestore(route));
  }

  @override
  Future<void> updateRoute(Route route) async {
    final docRef = _docRefForRoute(route);
    await docRef.set(FirestoreRouteMapper.toFirestore(route));
  }

  @override
  Future<void> deleteRoute(String routeId) async {
    await _routesCollection.doc(routeId).delete();
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
