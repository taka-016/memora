import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/usecases/member/calculate_school_grade_usecase.dart';
import 'package:memora/application/usecases/member/calculate_yakudoshi_usecase.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';

class MemberRow extends TimelineRowDefinition {
  const MemberRow({required this.member, required this.initialHeight});

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
    return _MemberYearCell(
      member: member,
      targetYear: year,
      displaySettings: rowContext.controller.displaySettings,
    );
  }
}

class _MemberYearCell extends ConsumerWidget {
  const _MemberYearCell({
    required this.member,
    required this.targetYear,
    required this.displaySettings,
  });

  final GroupMemberDto member;
  final int targetYear;
  final TimelineDisplaySettings displaySettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = _buildMemberLabels(
      birthday: member.birthday,
      gender: member.gender,
      targetYear: targetYear,
      displaySettings: displaySettings,
      calculateSchoolGrade: ref.read(calculateSchoolGradeUsecaseProvider),
      calculateYakudoshi: ref.read(calculateYakudoshiUsecaseProvider),
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

List<String> _buildMemberLabels({
  required DateTime? birthday,
  required String? gender,
  required int targetYear,
  required TimelineDisplaySettings displaySettings,
  required CalculateSchoolGradeUsecase calculateSchoolGrade,
  required CalculateYakudoshiUsecase calculateYakudoshi,
}) {
  final labels = <String>[
    if (displaySettings.showAge) ...?_buildAgeLabel(birthday, targetYear),
    if (displaySettings.showGrade)
      ...?_buildOptionalLabel(
        calculateSchoolGrade.execute(birthday, targetYear),
      ),
    if (displaySettings.showYakudoshi)
      ...?_buildOptionalLabel(
        calculateYakudoshi.execute(birthday, gender, targetYear),
      ),
  ];

  return labels;
}

List<String>? _buildAgeLabel(DateTime? birthday, int targetYear) {
  if (birthday == null) {
    return null;
  }

  final age = targetYear - birthday.year;
  if (age < 0) {
    return null;
  }

  return ['$age歳'];
}

List<String>? _buildOptionalLabel(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return [value];
}
