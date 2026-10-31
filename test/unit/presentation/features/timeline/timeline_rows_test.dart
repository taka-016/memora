import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_rows.dart';
import 'package:memora/presentation/features/timeline/dvc_row.dart';
import 'package:memora/presentation/features/timeline/group_event_row.dart';
import 'package:memora/presentation/features/timeline/member_row.dart';
import 'package:memora/presentation/features/timeline/trip_row.dart';

void main() {
  test('旅行・グループ・DVCの行背景は明暗どちらでも本文を読める', () {
    final rows = buildTimelineRows(
      groupWithMembers: const GroupDto(
        id: 'g',
        ownerId: 'o',
        name: '家族',
        members: [],
      ),
      onTripSelected: null,
      onDvcSelected: null,
    );
    for (final brightness in Brightness.values) {
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.lightBlue,
        brightness: brightness,
      );
      for (final row in rows) {
        final background = Color.alphaBlend(
          row.backgroundColor ?? Colors.transparent,
          scheme.surface,
        );
        final a = scheme.onSurface.computeLuminance();
        final b = background.computeLuminance();
        expect(
          a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });

  test('メンバー行は所属色を不透明度10%で共通背景として返す', () {
    const row = MemberRow(
      member: GroupMemberDto(
        groupId: 'g',
        memberId: 'm',
        displayName: '太郎',
        color: '#123456',
      ),
      initialHeight: 60,
    );
    expect(row.fixedColumnBackgroundColor, row.backgroundColor);
    expect(row.backgroundColor, const Color(0xFF123456).withValues(alpha: 0.1));
  });

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
        onTripSelected: null,
        onDvcSelected: null,
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
        onTripSelected: null,
        onDvcSelected: null,
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
