import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/usecases/member/calculate_school_grade_usecase.dart';
import 'package:memora/application/usecases/member/calculate_yakudoshi_usecase.dart';
import 'package:memora/application/usecases/member/get_member_events_usecase.dart';
import 'package:memora/application/usecases/member/save_member_event_usecase.dart';
import 'package:memora/presentation/features/member/member_event_edit_modal.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_rows_refresh_provider.dart';

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
  Key yearCellKey(int year) =>
      Key('member_event_cell_${member.memberId}_$year');

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
      availableHeight: rowContext.rowHeight,
      availableWidth: rowContext.layoutConfig.yearColumnWidth,
    );
  }
}

final _memberEventsByYearProvider = FutureProvider.autoDispose
    .family<Map<int, MemberEventDto>, String>((ref, memberId) async {
      ref.watch(timelineRowsRefreshProvider);
      final events = await ref.watch(getMemberEventsUsecaseProvider).execute([
        memberId,
      ]);
      return {for (final event in events) event.year: event};
    }, retry: (_, _) => null);

class _MemberYearCell extends HookConsumerWidget {
  const _MemberYearCell({
    required this.member,
    required this.targetYear,
    required this.displaySettings,
    required this.availableHeight,
    required this.availableWidth,
  });

  final GroupMemberDto member;
  final int targetYear;
  final TimelineDisplaySettings displaySettings;
  final double availableHeight;
  final double availableWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsByYear = ref.watch(
      _memberEventsByYearProvider(member.memberId),
    );
    final localEvent = useState<MemberEventDto?>(null);
    final loadedEvent = eventsByYear.value?[targetYear];

    useEffect(() {
      localEvent.value = loadedEvent;
      return null;
    }, [loadedEvent]);

    final currentEvent = localEvent.value;
    final memberLabels = _buildMemberLabels(
      birthday: member.birthday,
      gender: member.gender,
      targetYear: targetYear,
      displaySettings: displaySettings,
      calculateSchoolGrade: ref.read(calculateSchoolGradeUsecaseProvider),
      calculateYakudoshi: ref.read(calculateYakudoshiUsecaseProvider),
    );

    return eventsByYear.when(
      data: (_) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final eventAtOpen = localEvent.value;
          await showMemberEventEditModal(
            context: context,
            memberId: member.memberId,
            memberName: member.displayName,
            selectedYear: targetYear,
            initialMemo: eventAtOpen?.memo ?? '',
            onSave: (memo) async {
              if (memo.isEmpty) {
                await ref
                    .read(saveMemberEventUsecaseProvider)
                    .execute(
                      MemberEventDto(
                        id: eventAtOpen?.id ?? '',
                        memberId: member.memberId,
                        year: targetYear,
                        memo: '',
                      ),
                    );
                if (!context.mounted) {
                  return;
                }
                localEvent.value = null;
              } else {
                final savedEvent = await ref
                    .read(saveMemberEventUsecaseProvider)
                    .execute(
                      MemberEventDto(
                        id: eventAtOpen?.id ?? '',
                        memberId: member.memberId,
                        year: targetYear,
                        memo: memo,
                      ),
                    );
                if (!context.mounted) {
                  return;
                }
                localEvent.value = savedEvent;
              }
              ref.invalidate(_memberEventsByYearProvider(member.memberId));
            },
          );
        },
        child: _MemberCellContent(
          lines: [...memberLabels, ..._buildMemoLabels(currentEvent?.memo)],
          availableHeight: availableHeight,
          availableWidth: availableWidth,
        ),
      ),
      error: (_, _) => _MemberCellContent(
        lines: memberLabels,
        availableHeight: availableHeight,
        availableWidth: availableWidth,
      ),
      loading: () => _MemberCellContent(
        lines: memberLabels,
        availableHeight: availableHeight,
        availableWidth: availableWidth,
      ),
    );
  }
}

class _MemberCellContent extends StatelessWidget {
  const _MemberCellContent({
    required this.lines,
    required this.availableHeight,
    required this.availableWidth,
    this.footer,
  });

  final List<String> lines;
  final double availableHeight;
  final double availableWidth;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty && footer == null) {
      return const SizedBox.shrink();
    }

    final maxLines = (availableHeight / 20).floor().clamp(1, 20);
    final labelMaxLines = footer == null
        ? maxLines
        : (maxLines - 1).clamp(1, 20);

    return SizedBox(
      width: availableWidth,
      height: availableHeight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (lines.isNotEmpty)
              Flexible(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    lines.join('\n'),
                    maxLines: labelMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (footer case final footer?) SizedBox(height: 20, child: footer),
          ],
        ),
      ),
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

List<String> _buildMemoLabels(String? memo) {
  final trimmedMemo = memo?.trim();
  if (trimmedMemo == null || trimmedMemo.isEmpty) {
    return [];
  }

  return trimmedMemo.split('\n');
}
