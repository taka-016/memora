import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';

class MemberTimelineRow extends TimelineRowDefinition {
  MemberTimelineRow({required this.member, required super.initialHeight})
    : super(
        rowId: 'member_${member.memberId}',
        fixedColumnLabel: member.displayName,
      );

  final GroupMemberDto member;

  @override
  Widget buildYearCell({
    required BuildContext context,
    required TimelineRowContext rowContext,
    required int year,
    required double rowHeight,
    required double yearColumnWidth,
  }) {
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
