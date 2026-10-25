import 'dart:math' as math;

import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';

List<CalendarLabelDto> buildCalendarDisplayLabels(
  GroupDto group,
  List<CalendarLabelDto> customLabels, {
  List<CalendarEventDto> events = const [],
}) {
  CalendarLabelDto fixed(
    String id,
    String name,
    String color,
    String type, {
    String memberId = '',
    bool selectable = true,
  }) => CalendarLabelDto(
    id: id,
    groupId: group.id,
    name: name,
    color: color,
    textColor: calendarContrastingTextColor(color),
    labelType: type,
    memberId: memberId,
    isSelectable: selectable,
  );
  final members = group.members.toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  final result = [
    fixed('group:', 'グループの予定', group.color, 'group'),
    for (final member in members)
      fixed(
        'member:${member.memberId}',
        '${member.displayName}の予定',
        member.color,
        'member',
        memberId: member.memberId,
      ),
    ...customLabels,
  ];
  final missingMembers = <String>{};
  final currentMembers = members.map((v) => v.memberId).toSet();
  for (final event in events) {
    if (event.labelType == 'member' && !currentMembers.contains(event.memberId))
      missingMembers.add(event.memberId);
    for (final value in event.overrides.where(
      (v) => !v.isCancelled && v.labelType == 'member',
    )) {
      if (!currentMembers.contains(value.memberId))
        missingMembers.add(value.memberId);
    }
  }
  for (final memberId in missingMembers) {
    result.add(
      fixed(
        'member:$memberId',
        '所属解除・削除済みメンバーの予定',
        '#808080',
        'member',
        memberId: memberId,
        selectable: false,
      ),
    );
  }
  return List.unmodifiable(result);
}

String calendarContrastingTextColor(String hex) {
  final rgb = int.parse(hex.substring(1), radix: 16);
  double linear(int value) {
    final channel = value / 255;
    return channel <= 0.04045
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  final luminance =
      0.2126 * linear((rgb >> 16) & 255) +
      0.7152 * linear((rgb >> 8) & 255) +
      0.0722 * linear(rgb & 255);
  return luminance > 0.179 ? '#000000' : '#FFFFFF';
}
