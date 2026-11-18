import 'package:cloud_firestore/cloud_firestore.dart';

Future<String?> firestoreParentGroupId(
  FirebaseFirestore firestore,
  String collection,
  String parentId,
) async {
  final parent = await firestore.collection(collection).doc(parentId).get();
  if (!parent.exists) return null;
  return parent.data()!['groupId'] as String;
}
