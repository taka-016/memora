import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_event_input_notifier.dart';

import '../../../../helpers/calendar_group_test_support.dart';
import '../../../../helpers/calendar_group_test_support.mocks.dart';
import 'calendar_notifier_test.mocks.dart';
import '../../../../helpers/test_exception.dart';

void main() {
  test('切替先の固定ラベルへ戻し遅い取得結果を無視し失敗後も再試行できる', () async {
    final groups =
        calendarTestGroupLoader() as MockGetGroupWithMembersByIdUsecase;
    final labels = MockGetCalendarLabelsUsecase();
    when(labels.execute(any)).thenAnswer((_) async => []);
    final pending = Completer<GroupDto?>();
    when(groups.execute('a')).thenAnswer((_) => pending.future);
    final container = ProviderContainer(
      overrides: [
        getGroupWithMembersByIdUsecaseProvider.overrideWithValue(groups),
        getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
      ],
    );
    addTearDown(container.dispose);
    final provider = calendarEventInputNotifierProvider('session');
    container.listen(provider, (_, _) {});
    final notifier = container.read(provider.notifier);
    final old = notifier.selectGroup('a');
    await notifier.selectGroup('b');
    pending.complete(
      const GroupDto(id: 'a', ownerId: 'self', name: '旧', members: []),
    );
    await old;
    expect(container.read(provider).group?.id, 'b');
    expect(container.read(provider).selectedLabelKey, 'group:');
    notifier.selectLabel('custom');
    when(groups.execute('c')).thenThrow(TestException('取得失敗'));
    await notifier.selectGroup('c');
    expect(container.read(provider).groupId, 'c');
    expect(container.read(provider).selectedLabelKey, 'group:');
    expect(container.read(provider).error, isNotEmpty);
    when(groups.execute('c')).thenAnswer(
      (_) async =>
          const GroupDto(id: 'c', ownerId: 'self', name: '再試行', members: []),
    );
    await notifier.retry();
    expect(container.read(provider).group?.name, '再試行');
    expect(container.read(provider).error, isEmpty);
    await notifier.selectGroup(null);
    expect(container.read(provider).displayLabels, isEmpty);
  });
}
