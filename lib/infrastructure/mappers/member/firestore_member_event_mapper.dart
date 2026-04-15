import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/infrastructure/mappers/firestore_mapper_value_parser.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreMemberEventMapper {
  static final _defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

  static MemberEventDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MemberEventDto(
      id: doc.id,
      memberId: data['memberId'] as String? ?? '',
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

  static Map<String, dynamic> toCreateFirestore(MemberEvent memberEvent) {
    return {
      'memberId': memberEvent.memberId,
      'type': memberEvent.type,
      'name': memberEvent.name,
      'startDate': Timestamp.fromDate(memberEvent.startDate),
      'endDate': Timestamp.fromDate(memberEvent.endDate),
      'memo': memberEvent.memo,
      ...FirestoreWriteMetadata.forCreate(),
    };
  }
}
