import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/calendar_group_settings.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/features/setting/calendar_default_group_setting.dart';

class _Settings extends CalendarGroupSettingsNotifier {
  @override
  CalendarGroupSettingsState build() => CalendarGroupSettingsState(
    isLoading: false,
    groupsReady: true,
    groups: const [
      GroupDto(id: 'hidden', ownerId: 'self', name: '非表示グループ', members: []),
    ],
  );
  @override
  Future<bool> setDefaultGroup(String? id) async {
    state = state.copyWith(settings: CalendarGroupSettings(defaultGroupId: id));
    return true;
  }
}

void main() {
  testWidgets('非表示のグループと未設定を既定の保存先に選べる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarGroupSettingsNotifierProvider.overrideWith(_Settings.new),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CalendarDefaultGroupSetting()),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('非表示グループ').last);
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CalendarDefaultGroupSetting)),
    );
    expect(
      container
          .read(calendarGroupSettingsNotifierProvider)
          .settings
          .defaultGroupId,
      'hidden',
    );
    expect(
      container
          .read(calendarGroupSettingsNotifierProvider)
          .settings
          .visibleGroupIds,
      isEmpty,
    );
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('未設定').last);
    await tester.pumpAndSettle();
    expect(
      container
          .read(calendarGroupSettingsNotifierProvider)
          .settings
          .defaultGroupId,
      isNull,
    );
  });
}
