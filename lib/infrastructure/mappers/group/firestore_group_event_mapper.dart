import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/domain/entities/group/group_event.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreGroupEventMapper {
  static GroupEventDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return GroupEventDto(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      year: data['year'] as int? ?? 0,
      memo: data['memo'] as String? ?? '',
    );
  }

  static Map<String, dynamic> toCreateFirestore(GroupEvent groupEvent) {
    return {
      'groupId': groupEvent.groupId,
      'year': groupEvent.year,
      'memo': groupEvent.memo,
      ...FirestoreWriteMetadata.forCreate(),
    };
  }

  static Map<String, dynamic> toUpdateFirestore(GroupEvent groupEvent) {
    return {
      'groupId': groupEvent.groupId,
      'year': groupEvent.year,
      'memo': groupEvent.memo,
      ...FirestoreWriteMetadata.forUpdate(),
    };
  }
}
