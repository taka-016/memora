import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreMapperValueParser {
  const FirestoreMapperValueParser._();

  static int asInt(dynamic value, {int defaultValue = 0}) {
    if (value is num) {
      return value.toInt();
    }
    return defaultValue;
  }

  static int? asNullableInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static double asDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value is num) {
      return value.toDouble();
    }
    return defaultValue;
  }

  static DateTime? asDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
