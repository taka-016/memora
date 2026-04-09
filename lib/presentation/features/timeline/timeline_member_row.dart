import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';

class TimelineMemberRow extends TimelineRowDefinition {
  const TimelineMemberRow({
    required this.member,
    required this.initialHeight,
  });

  final GroupMemberDto member;

  @override
  final double initialHeight;

  @override
  String get fixedColumnLabel => member.displayName;

  @override
  Color? get backgroundColor => null;

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    final lines = rowContext.controller.buildMemberLabels(
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
