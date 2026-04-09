import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group/timeline_row_settings.dart';
import 'package:memora/domain/repositories/group/timeline_row_settings_repository.dart';
import 'package:memora/infrastructure/mappers/group/firestore_timeline_row_settings_mapper.dart';

class FirestoreTimelineRowSettingsRepository
    implements TimelineRowSettingsRepository {
  FirestoreTimelineRowSettingsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> createTimelineRowSettings(TimelineRowSettings settings) async {
    await _collection
        .doc(settings.groupId)
        .set(FirestoreTimelineRowSettingsMapper.toCreateFirestore(settings));
  }

  @override
  Future<void> updateTimelineRowSettings(TimelineRowSettings settings) async {
    await _collection
        .doc(settings.groupId)
        .update(FirestoreTimelineRowSettingsMapper.toUpdateFirestore(settings));
  }

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection('timeline_row_settings');
  }
}
