import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/models/startup_common_data.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/startup_common_data_providers.dart';
import 'package:memora/presentation/notifiers/startup/startup_common_data_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/features/calendar/calendar_event_input_page.dart';

import '../../../../helpers/calendar_group_settings_test_support.dart';

class _Common extends StartupCommonDataNotifier {
  final pending = Completer<void>();
  static const group = GroupDto(
    id: 'g1',
    ownerId: 'm1',
    name: '家族',
    members: [],
  );
  static const label = CalendarLabelDto(
    id: 'l1',
    groupId: 'g1',
    name: '旅行',
    color: '#123456',
  );
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
  Future<void> ensureLatest(String id) => pending.future;
  void removeLabel() => state = StartupCommonDataState(
    data: StartupCommonData(groups: [group], labels: {'g1': []}),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('確認失敗で入力画面を閉じず、裏で削除された選択ラベルを選び直せる', (tester) async {
    final common = _Common();
    var closed = false;
    final container = ProviderContainer(
      overrides: [
        startupCommonDataOwnerProvider.overrideWithValue('a1'),
        startupCommonDataNotifierProvider.overrideWith(() => common),
        calendarGroupSettingsNotifierProvider.overrideWith(
          () => TestCalendarGroupSettingsNotifier(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(startupCommonDataNotifierProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CalendarEventInputPage(
            date: DateTime(2026, 11, 15),
            onSaved: (_) => closed = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'タイトル'),
      '入力中の予定',
    );
    tester.testTextInput.hide();
    final dropdown = find.byWidgetPredicate(
      (w) =>
          w is DropdownButtonFormField<String> &&
          w.decoration.labelText == '色ラベル',
    );
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('旅行').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存'));
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(closed, isFalse);
    common.pending.completeError(
      const ApplicationValidationException('最新確認に失敗しました。再度保存してください'),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('最新確認に失敗しました。再度保存してください'));
    expect(find.text('入力中の予定'), findsOneWidget);
    expect(find.text('最新確認に失敗しました。再度保存してください'), findsOneWidget);
    common.removeLabel();
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('家族の予定').last);
    await tester.pumpAndSettle();
    expect(find.text('入力中の予定'), findsOneWidget);
    expect(closed, isFalse);
  });
}
