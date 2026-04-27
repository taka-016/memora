import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/infrastructure/mappers/firestore_mapper_value_parser.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreMemberEventMapper {
  static MemberEventDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MemberEventDto(
      id: doc.id,
      memberId: data['memberId'] as String? ?? '',
      year: FirestoreMapperValueParser.asInt(data['year']),
      memo: data['memo'] as String? ?? '',
    );
  }

  static Map<String, dynamic> toCreateFirestore(MemberEvent memberEvent) {
    return {
      'memberId': memberEvent.memberId,
      'year': memberEvent.year,
      'memo': memberEvent.memo,
      ...FirestoreWriteMetadata.forCreate(),
    };
  }

  static Map<String, dynamic> toUpdateFirestore(MemberEvent memberEvent) {
    return {
      'memberId': memberEvent.memberId,
      'year': memberEvent.year,
      'memo': memberEvent.memo,
      ...FirestoreWriteMetadata.forUpdate(),
    };
  }
}
