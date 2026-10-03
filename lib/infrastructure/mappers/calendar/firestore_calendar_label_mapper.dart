import 'package:memora/infrastructure/mappers/calendar/legacy_calendar_label_text_color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/calendar/calendar_label.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreCalendarLabelMapper {
  static CalendarLabelDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CalendarLabelDto(
      id: doc.id,
      groupId: data['groupId'] as String,
      name: data['name'] as String,
      sortOrder: data['sortOrder'] as int? ?? 0,
      color: data['color'] as String,
      textColor:
          data['textColor'] as String? ??
          legacyCalendarLabelTextColor(data['color'] as String),
    );
  }

  static Map<String, dynamic> toFirestore(CalendarLabel value) => {
    'groupId': value.groupId,
    'name': value.name,
    'color': value.color,
    'textColor': value.textColor,
    'sortOrder': value.sortOrder,
  };
  static Map<String, dynamic> toCreateFirestore(CalendarLabel value) => {
    ...toFirestore(value),
    ...FirestoreWriteMetadata.forCreate(),
  };
  static Map<String, dynamic> toUpdateFirestore(CalendarLabel value) => {
    ...toFirestore(value),
    ...FirestoreWriteMetadata.forUpdate(),
  };
}
