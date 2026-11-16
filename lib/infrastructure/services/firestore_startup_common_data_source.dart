import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/services/startup_common_data_source.dart';
import 'package:memora/infrastructure/queries/group/firestore_group_query_service.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_label_query_service.dart';

class FirestoreStartupCommonDataSource implements StartupCommonDataSource {
  FirestoreStartupCommonDataSource(FirebaseFirestore firestore)
    : _groups = FirestoreGroupQueryService(
        firestore: firestore,
        options: const GetOptions(source: Source.server),
      ),
      _labels = FirestoreCalendarLabelQueryService(
        firestore: firestore,
        options: const GetOptions(source: Source.server),
      );
  final FirestoreGroupQueryService _groups;
  final FirestoreCalendarLabelQueryService _labels;
  @override
  Future<List<GroupDto>> loadGroups(String memberId) =>
      _groups.getGroupsWithMembersByMemberId(memberId);
  @override
  Future<List<CalendarLabelDto>> loadLabels(String groupId) =>
      _labels.getCalendarLabelsByGroupId(groupId);
}
