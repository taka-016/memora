import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/timeline_row_settings_dto.dart';
import 'package:memora/domain/entities/group/timeline_row_settings.dart';

class FirestoreTimelineRowSettingsMapper {
  static TimelineRowSettingsDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rowsData = data['rows'] as List<dynamic>? ?? const [];

    return TimelineRowSettingsDto(
      groupId: data['groupId'] as String? ?? doc.id,
      rows: rowsData
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => TimelineRowSettingDto(
              rowId: row['rowId'] as String? ?? '',
              isVisible: row['isVisible'] as bool? ?? true,
              orderIndex: row['orderIndex'] as int? ?? 0,
            ),
          )
          .toList(),
    );
  }

  static Map<String, dynamic> toCreateFirestore(TimelineRowSettings settings) {
    return {
      ..._toFirestore(settings),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> toUpdateFirestore(TimelineRowSettings settings) {
    return _toFirestore(settings);
  }

  static Map<String, dynamic> _toFirestore(TimelineRowSettings settings) {
    return {
      'groupId': settings.groupId,
      'rows': [
        for (final row in settings.rows)
          {
            'rowId': row.rowId,
            'isVisible': row.isVisible,
            'orderIndex': row.orderIndex,
          },
      ],
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
