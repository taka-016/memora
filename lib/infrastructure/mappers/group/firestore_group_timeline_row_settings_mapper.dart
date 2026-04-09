import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/group_timeline_row_settings_dto.dart';
import 'package:memora/core/enums/group_timeline_row_type.dart';
import 'package:memora/domain/entities/group/group_timeline_row_settings.dart';

class FirestoreGroupTimelineRowSettingsMapper {
  static GroupTimelineRowSettingsDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rowsData = data['rows'] as List<dynamic>? ?? const [];

    return GroupTimelineRowSettingsDto(
      groupId: data['groupId'] as String? ?? doc.id,
      rows: rowsData
          .whereType<Map<String, dynamic>>()
          .map(_rowFromFirestore)
          .whereType<GroupTimelineRowSettingDto>()
          .toList(),
    );
  }

  static Map<String, dynamic> toCreateFirestore(
    GroupTimelineRowSettings settings,
  ) {
    return {
      ...toUpdateFirestore(settings),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> toUpdateFirestore(
    GroupTimelineRowSettings settings,
  ) {
    return {
      'groupId': settings.groupId,
      'rows': settings.rows.map(_rowToFirestore).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static GroupTimelineRowSettingDto? _rowFromFirestore(
    Map<String, dynamic> data,
  ) {
    final rowId = data['rowId'] as String?;
    final rowType = GroupTimelineRowType.fromName(data['rowType'] as String?);
    if (rowId == null || rowType == null) {
      return null;
    }

    return GroupTimelineRowSettingDto(
      rowId: rowId,
      rowType: rowType,
      targetId: data['targetId'] as String?,
      orderIndex: data['orderIndex'] as int? ?? 0,
      isVisible: data['isVisible'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> _rowToFirestore(GroupTimelineRowSetting setting) {
    return {
      'rowId': setting.rowId,
      'rowType': setting.rowType.name,
      'targetId': setting.targetId,
      'orderIndex': setting.orderIndex,
      'isVisible': setting.isVisible,
    };
  }
}
