import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/group_timeline_row_settings_dto.dart';
import 'package:memora/application/queries/group/group_timeline_row_settings_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_timeline_row_settings_mapper.dart';

class FirestoreGroupTimelineRowSettingsQueryService
    implements GroupTimelineRowSettingsQueryService {
  FirestoreGroupTimelineRowSettingsQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<GroupTimelineRowSettingsDto?> getGroupTimelineRowSettings(
    String groupId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('group_timeline_row_settings')
          .doc(groupId)
          .get();

      if (!snapshot.exists) {
        return null;
      }

      return FirestoreGroupTimelineRowSettingsMapper.fromFirestore(snapshot);
    } catch (e, stack) {
      logger.e(
        'FirestoreGroupTimelineRowSettingsQueryService.getGroupTimelineRowSettings: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }
}
