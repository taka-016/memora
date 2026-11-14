import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_labels_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import '../../../../helpers/calendar_group_test_support.dart';
import '../../../../helpers/fake_current_member_notifier.dart';
import '../../features/calendar/calendar_test_support.mocks.dart';
import 'calendar_notifier_test.mocks.dart';

class _Calendar extends CalendarNotifier {
  int loads = 0;
  @override
  CalendarState build(String groupId) => CalendarState(selectedDate: DateTime(2026, 11));
  @override
  Future<void> load() async { loads++; }
}
void main() {
  test('任意ラベルの保存後に表示中のオフライン予定とウィジェットを更新する', () async {
    final labels = MockGetCalendarLabelsUsecase();
    when(labels.execute(any)).thenAnswer((_) async => []);
    final calendar = _Calendar();
    int widgetUpdates = 0;
    final container = ProviderContainer(overrides: [
      currentMemberNotifierProvider.overrideWith(() => FakeCurrentMemberNotifier.loaded(const MemberDto(id: 'owner', displayName: '本人'))),
      getGroupWithMembersByIdUsecaseProvider.overrideWithValue(calendarTestGroupLoader()),
      getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
      calendarLabelManagementUsecaseProvider.overrideWithValue(MockCalendarLabelManagementUsecase()),
      calendarNotifierProvider('g1').overrideWith(() => calendar),
      refreshSelectedCalendarWidgetCacheProvider.overrideWithValue(() async { widgetUpdates++; }),
    ]);
    addTearDown(container.dispose);
    container.listen(calendarNotifierProvider('g1'), (_, _) {});
    container.listen(calendarLabelsNotifierProvider('g1'), (_, _) {});
    await container.pump();
    expect(await container.read(calendarLabelsNotifierProvider('g1').notifier).saveLabel(const CalendarLabelDto(id: 'label', groupId: 'g1', name: '家族', color: '#123456')), isTrue);
    expect(calendar.loads, 1);
    expect(widgetUpdates, 1);
  });
}
