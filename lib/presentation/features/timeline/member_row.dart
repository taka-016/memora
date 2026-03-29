import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';

class MemberRow extends StatelessWidget {
  const MemberRow({
    super.key,
    required this.member,
    required this.years,
    required this.displaySettings,
    required this.rowHeight,
    required this.yearColumnWidth,
    required this.buttonColumnWidth,
    required this.borderColor,
    required this.borderWidth,
    required this.buildSchoolGradeLabel,
    required this.buildYakudoshiLabel,
  });

  final GroupMemberDto member;
  final List<int> years;
  final TimelineDisplaySettings displaySettings;
  final double rowHeight;
  final double yearColumnWidth;
  final double buttonColumnWidth;
  final Color borderColor;
  final double borderWidth;
  final String? Function(DateTime? birthday, int targetYear)
  buildSchoolGradeLabel;
  final String? Function(DateTime? birthday, String? gender, int targetYear)
  buildYakudoshiLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildSideSpacer(),
        ...years.map(_buildYearCell),
        _buildSideSpacer(),
      ],
    );
  }

  Widget _buildSideSpacer() {
    return SizedBox(
      width: buttonColumnWidth,
      height: rowHeight,
      child: _buildCellContainer(child: const SizedBox.shrink()),
    );
  }

  Widget _buildYearCell(int year) {
    final lines = _buildLabels(year);

    return SizedBox(
      width: yearColumnWidth,
      height: rowHeight,
      child: _buildCellContainer(
        child: lines.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(lines.join('\n')),
              ),
      ),
    );
  }

  List<String> _buildLabels(int targetYear) {
    final ageLabel = displaySettings.showAge
        ? _buildAgeLabel(member.birthday, targetYear)
        : null;
    final gradeLabel = displaySettings.showGrade
        ? buildSchoolGradeLabel(member.birthday, targetYear)
        : null;
    final yakudoshiLabel = displaySettings.showYakudoshi
        ? buildYakudoshiLabel(member.birthday, member.gender, targetYear)
        : null;

    return [ageLabel, gradeLabel, yakudoshiLabel]
        .where((label) => label != null && label.isNotEmpty)
        .cast<String>()
        .toList();
  }

  String? _buildAgeLabel(DateTime? birthday, int targetYear) {
    if (birthday == null) {
      return null;
    }

    final age = targetYear - birthday.year;
    if (age < 0) {
      return null;
    }

    return '$age歳';
  }

  Widget _buildCellContainer({required Widget child}) {
    return Container(
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: borderWidth),
          right: BorderSide(color: borderColor, width: borderWidth),
        ),
      ),
      child: child,
    );
  }
}
