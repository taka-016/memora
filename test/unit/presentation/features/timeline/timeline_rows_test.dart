import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_rows.dart';
import 'package:memora/presentation/features/timeline/dvc_row.dart';
import 'package:memora/presentation/features/timeline/group_event_row.dart';
import 'package:memora/presentation/features/timeline/member_row.dart';
import 'package:memora/presentation/features/timeline/trip_row.dart';

void main() {
  group('buildTimelineRows', () {
    late GroupDto testGroupWithMembers;

    setUp(() {
      testGroupWithMembers = GroupDto(
        id: 'group1',
        ownerId: 'owner1',
        name: 'テストグループ',
        members: [
          GroupMemberDto(
            memberId: 'member1',
            groupId: 'group1',
            displayName: '花子',
            email: 'hanako@example.com',
          ),
          GroupMemberDto(
            memberId: 'member2',
            groupId: 'group1',
            displayName: '太郎',
            email: 'taro@example.com',
          ),
        ],
      );
    });

    test('行順未指定時は既存のデフォルト順を返す', () {
      final rowDefinitions = buildTimelineRows(
        groupWithMembers: testGroupWithMembers,
        onDestinationSelected: null,
      );

      expect(rowDefinitions, hasLength(5));
      expect(rowDefinitions[0], isA<TripRow>());
      expect(rowDefinitions[1], isA<GroupEventRow>());
      expect(rowDefinitions[2], isA<DvcRow>());
      expect(rowDefinitions[3], isA<MemberRow>());
      expect(rowDefinitions[4], isA<MemberRow>());
    });

    test('指定した行順でTimelineRowDefinitionを生成できる', () {
      final rowDefinitions = buildTimelineRows(
        groupWithMembers: testGroupWithMembers,
        onDestinationSelected: null,
        rowOrder: const [
          TimelineRowType.member,
          TimelineRowType.trip,
          TimelineRowType.dvc,
          TimelineRowType.groupEvent,
        ],
      );

      expect(rowDefinitions, hasLength(5));
      expect(rowDefinitions[0], isA<MemberRow>());
      expect(rowDefinitions[1], isA<MemberRow>());
      expect(rowDefinitions[2], isA<TripRow>());
      expect(rowDefinitions[3], isA<DvcRow>());
      expect(rowDefinitions[4], isA<GroupEventRow>());
    });
  });
}
