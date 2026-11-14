import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/usecases/calendar/move_calendar_event_usecase.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'move_calendar_event_usecase_test.mocks.dart';

@GenerateMocks([CalendarEventRepository, GetGroupsWithMembersUsecase])
void main() {
  final member = MemberDto(id: 'self', displayName: '本人');
  CalendarEventDto event({bool recurring = false}) => CalendarEventDto(id: 'e', version: 4, groupId: 'a', labelType: 'member', memberId: 'self', title: '予定', startDateTime: DateTime.utc(2026, 11, 1), endDateTime: DateTime.utc(2026, 11, 2), isAllDay: true, recurrenceRule: recurring ? 'FREQ=DAILY;COUNT=10' : null);
  late MockCalendarEventRepository repository;
  late MockGetGroupsWithMembersUsecase groups;
  late MoveCalendarEventUsecase usecase;
  setUp(() {
    repository = MockCalendarEventRepository(); groups = MockGetGroupsWithMembersUsecase();
    usecase = MoveCalendarEventUsecase(repository, groups);
    when(groups.execute(member)).thenAnswer((_) async => [for (final id in ['a', 'b']) GroupDto(id: id, ownerId: 'self', name: id, members: const [])]);
  });
  test('通常予定は取得時のIDと期待バージョンで移動先へ保存する', () async {
    final source = event();
    await usecase.execute(source, source.copyWith(groupId: 'b', labelType: 'group', memberId: ''), member);
    final arguments = verify(repository.moveCalendarEvent(captureAny, captureAny)).captured.cast<CalendarEvent>();
    expect(arguments.first.groupId, 'a'); expect(arguments.last.groupId, 'b');
    expect(arguments.last.id, 'e'); expect(arguments.last.version, 4);
  });
  test('系列移動では条件を保持し移動先のグループ固定ラベルへ戻す', () async {
    final source = event(recurring: true);
    await usecase.execute(source, source.copyWith(groupId: 'b', labelType: 'member', memberId: 'other'), member);
    final moved = verify(repository.moveCalendarEvent(any, captureAny)).captured.single as CalendarEvent;
    expect(moved.labelType, 'group'); expect(moved.memberId, isEmpty);
    expect(moved.recurrenceRule, source.recurrenceRule);
  });
  test('移動元・移動先のどちらかが所属外なら保存しない', () async {
    when(groups.execute(member)).thenAnswer((_) async => const []);
    await expectLater(usecase.execute(event(), event().copyWith(groupId: 'b'), member), throwsA(isA<ApplicationValidationException>()));
    verifyNever(repository.moveCalendarEvent(any, any));
  });
}
