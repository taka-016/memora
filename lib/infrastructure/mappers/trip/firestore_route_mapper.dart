import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/domain/entities/trip/route.dart';

class FirestoreRouteMapper {
  static Map<String, dynamic> toFirestore(Route route) {
    return {
      'tripId': route.tripId,
      'orderIndex': route.orderIndex,
      'departurePinId': route.departurePinId,
      'arrivalPinId': route.arrivalPinId,
      'travelMode': route.travelMode.apiValue,
      'distanceMeters': route.distanceMeters,
      'durationSeconds': route.durationSeconds,
      'instructions': route.instructions,
      'polyline': route.polyline,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
