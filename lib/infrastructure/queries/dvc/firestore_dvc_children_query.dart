import 'package:memora/infrastructure/services/firestore_measured_reads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/queries/order_by.dart';

Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> firestoreDvcChildren(
  FirebaseFirestore firestore,
  String collection,
  String groupId, {
  String? contractId,
  List<OrderBy>? orderBy,
}) async {
  final ids = contractId != null
      ? [contractId]
      : (await firestore
                .collection('dvc_point_contracts')
                .where('groupId', isEqualTo: groupId)
                .measuredGet(
                  'firestore_dvc_children_query.01',
                  target: 'dvc_point_contracts',
                ))
            .docs
            .map((doc) => doc.id)
            .toList();
  final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  for (final id in ids) {
    var query = firestore
        .collection(collection)
        .where('groupId', isEqualTo: groupId)
        .where('contractId', isEqualTo: id);
    for (final order in orderBy ?? const <OrderBy>[]) {
      query = query.orderBy(order.field, descending: order.descending);
    }
    docs.addAll(
      (await query.measuredGet(
        'firestore_dvc_children_query.02',
        target: collection,
      )).docs,
    );
  }
  if (orderBy != null) {
    docs.sort((a, b) {
      for (final order in orderBy) {
        final value = (a.data()[order.field] as Comparable).compareTo(
          b.data()[order.field],
        );
        if (value != 0) return order.descending ? -value : value;
      }
      return 0;
    });
  }
  return docs;
}
