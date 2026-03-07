import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/domain/entities/group/group_event.dart';
import 'package:memora/infrastructure/mappers/firestore_mapper_value_parser.dart';

class FirestoreGroupEventMapper {
  static final _defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

  static GroupEventDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return GroupEventDto(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      name: data['name'] as String?,
      startDate:
          FirestoreMapperValueParser.asDateTime(data['startDate']) ??
          _defaultDate,
      endDate:
          FirestoreMapperValueParser.asDateTime(data['endDate']) ??
          _defaultDate,
      memo: data['memo'] as String?,
    );
  }

  static Map<String, dynamic> toFirestore(GroupEvent groupEvent) {
    return {
      'groupId': groupEvent.groupId,
      'type': groupEvent.type,
      'name': groupEvent.name,
      'startDate': Timestamp.fromDate(groupEvent.startDate),
      'endDate': Timestamp.fromDate(groupEvent.endDate),
      'memo': groupEvent.memo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
