import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_event_mutation_result.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/usecases/calendar/create_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/update_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/delete_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/move_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/change_calendar_recurrence_usecase.dart';

class CalendarEventMutationUsecase {
  CalendarEventMutationUsecase({
    required this.create,
    required this.update,
    required this.deleteEvent,
    required this.move,
    required this.changeRecurrence,
  });

  final CreateCalendarEventUsecase Function() create;
  final UpdateCalendarEventUsecase Function() update;
  final DeleteCalendarEventUsecase Function() deleteEvent;
  final MoveCalendarEventUsecase Function() move;
  final ChangeCalendarRecurrenceUsecase Function() changeRecurrence;

  Future<CalendarEventMutationResult> save(
    CalendarEventDto input, {
    required MemberDto? Function() currentMember,
    CalendarEventDto? expected,
    CalendarEventDto? expectedSeries,
    CalendarChangeScope? scope,
  }) async {
    if (expected?.originalStartDateTime != null) {
      if (expectedSeries == null ||
          !_matchesSeries(expected!, expectedSeries)) {
        throw const ApplicationValidationException(
          '予定が変更されています。再読み込みしてからやり直してください',
        );
      }
    }
    final moving = expected != null && expected.groupId != input.groupId;
    String? savedId = input.id;
    if (moving) {
      final member = currentMember();
      if (member == null) {
        throw const ApplicationValidationException('利用者を確認できません。再読み込みしてください');
      }
      await move().execute(expectedSeries ?? expected, input, member);
    } else if (expected?.originalStartDateTime != null) {
      if (expectedSeries == null || scope == null) {
        throw const ApplicationValidationException(
          '変更する系列を確認できません。再読み込みしてください',
        );
      }
      savedId = await changeRecurrence().execute(
        expectedSeries,
        expected!.originalStartDateTime!,
        scope,
        changes: input,
      );
    } else if (input.id.isEmpty) {
      savedId = await create().execute(input);
    } else {
      await update().execute(input);
    }
    return CalendarEventMutationResult(
      savedId: savedId,
      affectedGroupIds: {if (expected != null) expected.groupId, input.groupId},
    );
  }

  Future<CalendarEventMutationResult> delete(
    CalendarEventDto expected, {
    CalendarEventDto? expectedSeries,
    CalendarChangeScope? scope,
  }) async {
    if (expected.originalStartDateTime != null) {
      if (expectedSeries != null && !_matchesSeries(expected, expectedSeries)) {
        throw const ApplicationValidationException(
          '予定が変更されています。再読み込みしてからやり直してください',
        );
      }
      if (expectedSeries == null || scope == null) {
        throw const ApplicationValidationException(
          '変更する系列を確認できません。再読み込みしてください',
        );
      }
      await changeRecurrence().execute(
        expectedSeries,
        expected.originalStartDateTime!,
        scope,
      );
    } else {
      await deleteEvent().execute(
        expected.id,
        expectedVersion: expected.version,
      );
    }
    return CalendarEventMutationResult(affectedGroupIds: {expected.groupId});
  }

  bool _matchesSeries(CalendarEventDto expected, CalendarEventDto series) =>
      series.version == expected.version &&
      series.overridesFingerprint == expected.overridesFingerprint &&
      series.copyWith(
            startDateTime: expected.startDateTime,
            endDateTime: expected.endDateTime,
            originalStartDateTime: expected.originalStartDateTime,
            overrides: expected.overrides,
          ) ==
          expected;
}
