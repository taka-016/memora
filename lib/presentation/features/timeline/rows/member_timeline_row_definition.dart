import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_context.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_definition.dart';

class MemberTimelineRowDefinition extends TimelineRowDefinition {
  const MemberTimelineRowDefinition({
    required this.member,
    required this.initialHeight,
  });

  static String rowIdFor(String memberId) {
    return 'member:$memberId';
  }

  final GroupMemberDto member;

  @override
  final double initialHeight;

  @override
  String get rowId => rowIdFor(member.memberId);

  @override
  String get fixedColumnLabel => member.displayName;

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    final lines = rowContext.memberLabels(member: member, targetYear: year);

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Text(lines.join('\n')),
    );
  }
}
