import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreWriteMetadata {
  static Map<String, dynamic> forCreate() {
    return {
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> forUpdate() {
    return {'updatedAt': FieldValue.serverTimestamp()};
  }
}
