import 'package:memora/infrastructure/services/firestore_measured_reads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<String?> firestoreParentGroupId(
  FirebaseFirestore firestore,
  String collection,
  String parentId,
) async {
  final parent = await firestore
      .collection(collection)
      .doc(parentId)
      .measuredGet('firestore_parent_group_id.01');
  if (!parent.exists) return null;
  return parent.data()!['groupId'] as String;
}
