import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/usecases/calendar/save_calendar_label_usecase.dart';
import 'package:memora/application/usecases/calendar/delete_calendar_label_usecase.dart';
import 'package:memora/application/usecases/calendar/reorder_calendar_labels_usecase.dart';
import 'package:memora/application/usecases/group/get_group_with_members_by_id_usecase.dart';
import 'package:memora/domain/repositories/calendar/calendar_label_repository.dart';

class CalendarLabelManagementUsecase {
  CalendarLabelManagementUsecase(this._repository, this._groups);
  final CalendarLabelRepository _repository;
  final GetGroupWithMembersByIdUsecase _groups;
  Future<void> _authorize(String groupId, String memberId) async {
    final group = await _groups.execute(groupId);
    if (group == null || (group.ownerId != memberId && !group.members.any((m) => m.memberId == memberId && m.isAdministrator))) {
      throw const ApplicationValidationException('色ラベルを管理できるのは所有者と管理者だけです');
    }
  }
  Future<void> save(CalendarLabelDto label, String memberId) async {
    await _authorize(label.groupId, memberId);
    await SaveCalendarLabelUsecase(_repository).execute(label);
  }
  Future<void> delete(String groupId, String id, String memberId, {int? expectedVersion}) async {
    await _authorize(groupId, memberId);
    await DeleteCalendarLabelUsecase(_repository).execute(id, expectedVersion: expectedVersion);
  }
  Future<void> reorder(String groupId, List<String> ids, String memberId, {Map<String, int> expectedVersions = const {}}) async {
    await _authorize(groupId, memberId);
    await ReorderCalendarLabelsUsecase(_repository).execute(groupId, ids, expectedVersions: expectedVersions);
  }
}
