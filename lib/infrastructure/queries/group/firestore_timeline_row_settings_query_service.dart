import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/timeline_row_settings_dto.dart';
import 'package:memora/application/queries/group/timeline_row_settings_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/mappers/group/firestore_timeline_row_settings_mapper.dart';

class FirestoreTimelineRowSettingsQueryService
    implements TimelineRowSettingsQueryService {
  FirestoreTimelineRowSettingsQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<TimelineRowSettingsDto?> getTimelineRowSettingsByGroupId(
    String groupId,
  ) async {
    try {
      final doc = await _firestore
          .collection('timeline_row_settings')
          .doc(groupId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return FirestoreTimelineRowSettingsMapper.fromFirestore(doc);
    } catch (e, stack) {
      logger.e(
        'FirestoreTimelineRowSettingsQueryService.getTimelineRowSettingsByGroupId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }
}
