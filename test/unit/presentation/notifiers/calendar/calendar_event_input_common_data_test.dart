import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/models/startup_common_data.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/startup_common_data_providers.dart';
import 'package:memora/presentation/notifiers/startup/startup_common_data_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_event_input_notifier.dart';

import '../../../../helpers/test_exception.dart';

const group = GroupDto(id: 'g1', ownerId: 'm1', name: '家族', members: []);
const label = CalendarLabelDto(
  id: 'l1',
  groupId: 'g1',
  name: '旅行',
  color: '#123456',
);

class _Common extends StartupCommonDataNotifier {
  Completer<void> pending = Completer();
  @override
  StartupCommonDataState build() => StartupCommonDataState(
    data: StartupCommonData(
      groups: [group],
      labels: {
        'g1': [label],
      },
    ),
  );
  @override
  Future<void> ensureLatest(String groupId) => pending.future;
  void update({
    List<GroupDto> groups = const [group],
    List<CalendarLabelDto> labels = const [],
  }) {
    state = StartupCommonDataState(
      data: StartupCommonData(groups: groups, labels: {'g1': labels}),
      groupsConfirmed: true,
      labelsConfirmed: {'g1'},
    );
  }
}

void main() {
  late ProviderContainer container;
  late _Common common;
  final input = calendarEventInputNotifierProvider('入力');
  setUp(() {
    common = _Common();
    container = ProviderContainer(
      overrides: [
        startupCommonDataOwnerProvider.overrideWithValue('a1'),
        startupCommonDataNotifierProvider.overrideWith(() => common),
      ],
    );
    container.read(startupCommonDataNotifierProvider);
    container.listen(input, (_, _) {});
  });
  tearDown(() => container.dispose());

  test('キャッシュで選択でき裏の更新後も選択中のラベルを残す', () async {
    final notifier = container.read(input.notifier);
    await notifier.selectGroup('g1');
    expect(container.read(input).group, group);
    expect(container.read(input).isLoading, isFalse);
    notifier.selectLabel('l1');
    common.update();
    expect(container.read(input).selectedLabelKey, 'l1');
    expect(container.read(input).labels, isEmpty);
    common.pending.complete();
    await expectLater(
      notifier.validateForSave(),
      throwsA(isA<ApplicationValidationException>()),
    );
  });

  test('保存時に進行中の確認を待ち、失敗後も選択を保持して再試行できる', () async {
    final notifier = container.read(input.notifier);
    await notifier.selectGroup('g1');
    notifier.selectLabel('l1');
    final saving = notifier.validateForSave();
    final failure = expectLater(saving, throwsA(isA<TestException>()));
    common.pending.completeError(TestException('通信失敗'));
    await failure;
    expect(container.read(input).selectedLabelKey, 'l1');
    common.pending = Completer()..complete();
    await notifier.validateForSave();
    common.update(groups: []);
    expect(container.read(input).error, contains('選び直してください'));
    await expectLater(
      notifier.validateForSave(),
      throwsA(isA<ApplicationValidationException>()),
    );
  });
}
