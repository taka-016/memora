import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/models/calendar_group_settings.dart';
import 'package:memora/application/services/calendar_group_settings_storage.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/usecases/android_widget/get_calendar_widget_selection_usecase.dart';

import 'get_calendar_widget_selection_usecase_test.mocks.dart';

class _Settings implements CalendarGroupSettingsStorage {
  CalendarGroupSettings value = CalendarGroupSettings(
    visibleGroupIds: {'mine', 'outside'},
    defaultGroupId: 'outside',
  );
  String? owner;
  @override
  Future<CalendarGroupSettings> load(String ownerId) async {
    owner = ownerId;
    return value;
  }

  @override
  Future<void> save(String ownerId, CalendarGroupSettings settings) async =>
      fail('背景更新は端末設定を書き換えない');
}

@GenerateNiceMocks([
  MockSpec<GetCurrentMemberUseCase>(),
  MockSpec<GroupQueryService>(),
])
void main() {
  for (final mode in AppMode.values) {
    test('${mode.name}のウィジェットは利用者ごとの設定と有効な所属を使う', () async {
      final member = MockGetCurrentMemberUseCase();
      final groups = MockGroupQueryService();
      final storage = _Settings();
      const current = MemberDto(id: 'me', accountId: 'uid', displayName: '本人');
      when(member.execute()).thenAnswer((_) async => current);
      when(groups.getGroupsWithMembersByMemberId(current.id)).thenAnswer(
        (_) async => [
          const GroupDto(id: 'mine', ownerId: 'me', name: '自分', members: []),
        ],
      );
      final usecase = GetCalendarWidgetSelectionUsecase(
        mode: mode,
        currentMember: member,
        groups: groups,
        storage: storage,
      );
      final selection = await usecase.execute();
      expect(selection!.visibleGroups.map((g) => g.id), ['mine']);
      expect(
        storage.owner,
        mode == AppMode.online ? 'online:uid' : 'offline:me',
      );
      final scope = selection.cacheScope;
      when(groups.getGroupIdsByMemberId(current.id))
          .thenAnswer((_) async => {'mine'});
      clearInteractions(groups);
      expect(await usecase.loadCurrentScope(), scope);
      when(groups.getGroupIdsByMemberId(current.id))
          .thenAnswer((_) async => <String>{});
      expect(await usecase.loadCurrentScope(), isNot(scope));
      verify(groups.getGroupIdsByMemberId(current.id)).called(2);
      verifyNoMoreInteractions(groups);
      storage.value = CalendarGroupSettings();
      expect((await usecase.execute())!.visibleGroups, isEmpty);
      expect((await usecase.execute())!.cacheScope, isNot(scope));
      storage.value = CalendarGroupSettings(hasSavedSettings: false);
      expect((await usecase.execute())!.visibleGroups, isEmpty);
      when(member.execute()).thenAnswer((_) async => null);
      expect(await usecase.execute(), isNull);
      expect(await usecase.loadCurrentScope(), isNull);
    });
  }
}
