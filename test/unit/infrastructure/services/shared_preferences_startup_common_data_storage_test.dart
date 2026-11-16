import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/models/startup_common_data.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/infrastructure/services/shared_preferences_startup_common_data_storage.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('再起動後もアカウントごとの所属とラベルを復元し、未取得と空の取得済みを区別する', () async {
    final member = GroupMemberDto(
      memberId: 'm1',
      groupId: 'g1',
      displayName: '本人',
      birthday: DateTime(2000, 1, 2),
      isAdministrator: true,
      textColor: '#112233',
    );
    final group = GroupDto(
      id: 'g1',
      ownerId: 'm1',
      name: '家族',
      version: 3,
      members: [member],
      originalMembers: [member],
      textColor: '#445566',
    );
    const label = CalendarLabelDto(
      id: 'l1',
      groupId: 'g1',
      name: '旅行',
      color: '#778899',
      sortOrder: 2,
      version: 4,
    );
    await const SharedPreferencesStartupCommonDataStorage().save(
      'a:1',
      StartupCommonData(
        groups: [group],
        labels: {
          'g1': [label],
          'g2': [],
        },
      ),
    );
    final restored = await const SharedPreferencesStartupCommonDataStorage()
        .load('a:1');
    expect(restored!.groups, [group]);
    expect(restored.labels['g1'], [label]);
    expect(restored.labels['g2'], isEmpty);
    expect(restored.labels.containsKey('g3'), isFalse);
    expect(
      await const SharedPreferencesStartupCommonDataStorage().load('a:2'),
      isNull,
    );
  });
}
