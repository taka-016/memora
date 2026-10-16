import 'package:memora/infrastructure/repositories/firestore_write_context.dart';

class FirestoreDeletedParentStore {
  const FirestoreDeletedParentStore(this.context);

  final FirestoreWriteContext context;

  void saveGroup(String groupId, Map<String, dynamic> data) {
    context.set(context.collection('deleted_groups').doc(groupId), data);
  }

  void saveMember(String memberId, Map<String, dynamic> data) {
    context.set(context.collection('deleted_members').doc(memberId), data);
  }
}
