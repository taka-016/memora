import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreLocationMapper {
  static LocationDto fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LocationDto(
      id: doc.id,
      tripId: _requiredString(data, 'tripId'),
      groupId: _requiredString(data, 'groupId'),
      name: data['name'] as String?,
      latitude: _requiredDouble(data, 'latitude'),
      longitude: _requiredDouble(data, 'longitude'),
    );
  }

  static Map<String, dynamic> toCreateFirestore(Location location) {
    return {
      'tripId': location.tripId,
      'groupId': location.groupId,
      'name': location.name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      ...FirestoreWriteMetadata.forCreate(),
    };
  }

  static Map<String, dynamic> toUpdateFirestore(Location location) {
    return {
      'tripId': location.tripId,
      'groupId': location.groupId,
      'name': location.name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      ...FirestoreWriteMetadata.forUpdate(),
    };
  }

  static String _requiredString(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is String) {
      return value;
    }
    throw FormatException('locations.$field は文字列である必要があります');
  }

  static double _requiredDouble(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is num) {
      return value.toDouble();
    }
    throw FormatException('locations.$field は数値である必要があります');
  }
}
