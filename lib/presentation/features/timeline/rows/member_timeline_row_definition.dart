import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_context.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_definition.dart';

class MemberTimelineRowDefinition extends TimelineRowDefinition {
  const MemberTimelineRowDefinition({
    required super.rowId,
    required super.initialHeight,
    required this.member,
  });

  final GroupMemberDto member;

  @override
  bool isVisible(TimelineRowContext rowContext) => true;

  @override
  Widget buildFixedColumn(BuildContext context, TimelineRowContext rowContext) {
    return Text(member.displayName);
  }

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    final lines = rowContext.buildMemberLabels(
      birthday: member.birthday,
      gender: member.gender,
      targetYear: year,
    );

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Text(lines.join('\n')),
    );
  }
}
