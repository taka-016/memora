import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';

class MoveCalendarEventUsecase {
  MoveCalendarEventUsecase(this._repository, this._groups);
  final CalendarEventRepository _repository;
  final GetGroupsWithMembersUsecase _groups;

  Future<void> execute(CalendarEventDto expected, CalendarEventDto changes, MemberDto member) async {
    final groups = await _groups.execute(member);
    final ids = groups.map((g) => g.id).toSet();
    if (expected.id.isEmpty || changes.id != expected.id || expected.originalStartDateTime != null ||
        expected.groupId == changes.groupId || !ids.contains(expected.groupId) || !ids.contains(changes.groupId)) {
      throw const ApplicationValidationException('移動元と移動先の所属を確認できません。再読み込みしてください');
    }
    try {
      final recurring = expected.recurrenceRule != null;
      final replacement = CalendarEvent(
        id: expected.id, version: expected.version,
        overridesFingerprint: expected.overridesFingerprint,
        groupId: changes.groupId,
        labelType: recurring ? 'group' : changes.labelType,
        memberId: recurring ? '' : changes.memberId,
        labelId: recurring ? '' : changes.labelId,
        title: changes.title, url: changes.url, memo: changes.memo,
        locationName: changes.locationName, latitude: changes.latitude, longitude: changes.longitude,
        startDateTime: recurring ? expected.startDateTime : changes.startDateTime,
        endDateTime: recurring ? expected.endDateTime : changes.endDateTime,
        isAllDay: recurring ? expected.isAllDay : changes.isAllDay,
        notificationMinutesBefore: changes.notificationMinutesBefore,
        recurrenceRule: recurring ? expected.recurrenceRule : changes.recurrenceRule, timeZone: recurring ? expected.timeZone : changes.timeZone, overrides: expected.overrides,
      );
      await _repository.moveCalendarEvent(CalendarEventMapper.toEntity(expected), replacement);
    } on ValidationException catch (error, stack) {
      Error.throwWithStackTrace(ApplicationValidationException(error.message), stack);
    }
  }
}
