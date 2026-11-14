import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/usecases/calendar/move_calendar_event_usecase.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_mutation_coordinator.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import '../../../../helpers/fake_current_member_notifier.dart';
import '../../../../helpers/test_exception.dart';
import 'calendar_mutation_coordinator_test.mocks.dart';

@GenerateMocks([MoveCalendarEventUsecase])
void main() {
  test('移動成功後に変更前後を再取得しウィジェットを更新し失敗時は更新しない', () async {
    final calls = <String>[];
    final move = MockMoveCalendarEventUsecase();
    final container = ProviderContainer(overrides: [
      moveCalendarEventUsecaseProvider.overrideWithValue(move),
      currentMemberNotifierProvider.overrideWith(() => FakeCurrentMemberNotifier.loaded(const MemberDto(id: 'self', displayName: '本人'))),
      refreshSelectedCalendarWidgetCacheProvider.overrideWithValue(() async { calls.add('widget'); }),
      calendarNotifierProvider('a').overrideWith(() => _Calendar(calls)),
      calendarNotifierProvider('b').overrideWith(() => _Calendar(calls)),
    ]);
    addTearDown(container.dispose);
    container.listen(calendarNotifierProvider('a'), (_, _) {});
    container.listen(calendarNotifierProvider('b'), (_, _) {});
    final source = CalendarEventDto(id: 'event', groupId: 'a', labelType: 'group', title: '予定', startDateTime: DateTime.utc(2026, 11, 1), endDateTime: DateTime.utc(2026, 11, 2), isAllDay: true);
    final coordinator = container.read(calendarMutationCoordinatorProvider);
    await coordinator.save(source.copyWith(groupId: 'b'), expected: source);
    expect(calls.toSet(), {'a', 'b', 'widget'});
    calls.clear();
    when(move.execute(any, any, any)).thenThrow(TestException('移動失敗'));
    await expectLater(coordinator.save(source.copyWith(groupId: 'b'), expected: source), throwsA(isA<TestException>()));
    expect(calls, isEmpty);
  });
}
class _Calendar extends CalendarNotifier {
  _Calendar(this.calls);
  final List<String> calls;
  @override
  CalendarState build(String groupId) => CalendarState(selectedDate: DateTime(2026, 11));
  @override
  Future<void> load() async { calls.add(groupId); }
}
