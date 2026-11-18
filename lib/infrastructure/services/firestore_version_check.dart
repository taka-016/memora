import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreVersionCheck {
  static void requireMatch(Map<String, dynamic>? data, int? expectedVersion) {
    if (expectedVersion == null ||
        expectedVersion < 1 ||
        data == null ||
        data['version'] is! int ||
        data['version'] != expectedVersion) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'aborted',
        message: 'データが変更または削除されています。再読み込みしてください。',
      );
    }
  }

  static void requireAbsent(Map<String, dynamic>? data) {
    if (data != null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'aborted',
        message: 'データが既に作成されています。再読み込みしてください。',
      );
    }
  }

  static Future<void> delete(
    FirebaseFirestore firestore,
    DocumentReference<Map<String, dynamic>> reference,
    int? expectedVersion,
  ) async {
    await firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(reference);
      requireMatch(snapshot.data(), expectedVersion);
      transaction.delete(reference);
    });
  }
}
