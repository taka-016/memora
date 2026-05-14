import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/core/time/app_clock.dart';

class FirestoreServerClock implements AppClock {
  FirestoreServerClock({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _collectionPath = '_app_metadata';
  static const _documentPath = 'server_clock';
  static const _fieldName = 'requestedAt';

  final FirebaseFirestore _firestore;

  @override
  Future<DateTime> nowUtc() async {
    final document = _firestore.collection(_collectionPath).doc(_documentPath);
    await document.set({
      _fieldName: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final snapshot = await document.get(
      const GetOptions(source: Source.server),
    );
    final value = snapshot.data()?[_fieldName];
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }

    throw StateError('サーバー時刻を取得できませんでした');
  }
}
