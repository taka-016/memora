import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group/group_timeline_row_settings.dart';
import 'package:memora/domain/repositories/group/group_timeline_row_settings_repository.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_timeline_row_settings_mapper.dart';

class FirestoreGroupTimelineRowSettingsRepository
    implements GroupTimelineRowSettingsRepository {
  FirestoreGroupTimelineRowSettingsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveGroupTimelineRowSettings(
    GroupTimelineRowSettings settings,
  ) async {
    final docRef = _firestore
        .collection('group_timeline_row_settings')
        .doc(settings.groupId);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      await docRef.update(
        FirestoreGroupTimelineRowSettingsMapper.toUpdateFirestore(settings),
      );
      return;
    }

    await docRef.set(
      FirestoreGroupTimelineRowSettingsMapper.toCreateFirestore(settings),
    );
  }
}
