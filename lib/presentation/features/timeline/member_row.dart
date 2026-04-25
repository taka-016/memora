import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/usecases/member/calculate_school_grade_usecase.dart';
import 'package:memora/application/usecases/member/calculate_yakudoshi_usecase.dart';
import 'package:memora/application/usecases/member/get_member_events_usecase.dart';
import 'package:memora/application/usecases/member/save_member_event_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/member/member_event_edit_modal.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';

class MemberRow extends TimelineRowDefinition {
  const MemberRow({
    required this.member,
    required this.memberIds,
    required this.initialHeight,
  });

  final GroupMemberDto member;
  final List<String> memberIds;

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
      memberIds: memberIds,
      targetYear: year,
      displaySettings: rowContext.controller.displaySettings,
      refreshKey: rowContext.controller.refreshKey,
    );
  }
}

final _memberEventsByMemberIdProvider = FutureProvider.autoDispose
    .family<Map<String, Map<int, MemberEventDto>>, _MemberEventsQuery>((
      ref,
      query,
    ) async {
      try {
        final getMemberEventsUsecase = ref.watch(
          getMemberEventsUsecaseProvider,
        );
        final events = await getMemberEventsUsecase.execute(query.memberIds);
        final eventsByMemberId = <String, Map<int, MemberEventDto>>{};
        for (final event in events) {
          eventsByMemberId.putIfAbsent(event.memberId, () => {})[event.year] =
              event;
        }
        return eventsByMemberId;
      } catch (e, stack) {
        logger.e(
          'MemberRow.loadMemberEvents: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        return {};
      }
    });

class _MemberYearCell extends HookConsumerWidget {
  const _MemberYearCell({
    required this.member,
    required this.memberIds,
    required this.targetYear,
    required this.displaySettings,
    required this.refreshKey,
  });

  final GroupMemberDto member;
  final List<String> memberIds;
  final int targetYear;
  final TimelineDisplaySettings displaySettings;
  final int refreshKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = _MemberEventsQuery(
      memberIds: memberIds,
      refreshKey: refreshKey,
    );
    final eventsByMemberId = ref.watch(_memberEventsByMemberIdProvider(query));
    final localEvent = useState<MemberEventDto?>(null);
    final loadedEvent =
        eventsByMemberId.valueOrNull?[member.memberId]?[targetYear];

    useEffect(() {
      localEvent.value = loadedEvent;
      return null;
    }, [loadedEvent]);

    final lines = _buildMemberLabels(
      birthday: member.birthday,
      gender: member.gender,
      targetYear: targetYear,
      displaySettings: displaySettings,
      calculateSchoolGrade: ref.read(calculateSchoolGradeUsecaseProvider),
      calculateYakudoshi: ref.read(calculateYakudoshiUsecaseProvider),
    );
    final currentEvent = localEvent.value;
    final eventMemo = currentEvent?.memo.trim();
    final displayLines = [
      ...lines,
      if (eventMemo != null && eventMemo.isNotEmpty) eventMemo,
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final eventAtOpen = localEvent.value;
        await showMemberEventEditModal(
          context: context,
          memberId: member.memberId,
          selectedYear: targetYear,
          initialMemo: eventAtOpen?.memo ?? '',
          onSave: (memo) async {
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
            localEvent.value = memo.isEmpty ? null : savedEvent;
            ref.invalidate(_memberEventsByMemberIdProvider(query));
          },
        );
      },
      child: displayLines.isEmpty
          ? const SizedBox.expand()
          : SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(displayLines.join('\n')),
              ),
            ),
    );
  }
}

class _MemberEventsQuery {
  _MemberEventsQuery({
    required List<String> memberIds,
    required this.refreshKey,
  }) : memberIds = List.unmodifiable(memberIds);

  final List<String> memberIds;
  final int refreshKey;

  @override
  bool operator ==(Object other) {
    return other is _MemberEventsQuery &&
        _listEquals(other.memberIds, memberIds) &&
        other.refreshKey == refreshKey;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(memberIds), refreshKey);
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
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
