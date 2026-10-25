import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/services/calendar/calendar_display_labels.dart';

void main() {
  test('任意ラベルがなくてもグループと所属順の固定ラベルを組み立てる', () {
    const group = GroupDto(
      id: 'g',
      ownerId: 'm',
      name: '家族',
      color: '#000000',
      members: [
        GroupMemberDto(
          groupId: 'g',
          memberId: 'a',
          displayName: '花子',
          color: '#FFFFFF',
          orderIndex: 1,
        ),
        GroupMemberDto(
          groupId: 'g',
          memberId: 'b',
          displayName: '太郎',
          orderIndex: 0,
        ),
      ],
    );
    final labels = buildCalendarDisplayLabels(group, const [
      CalendarLabelDto(id: 'l', groupId: 'g', name: '仕事', color: '#123456'),
    ]);
    expect(labels.map((v) => v.name), ['グループの予定', '太郎の予定', '花子の予定', '仕事']);
    expect(labels.first.textColor, '#FFFFFF');
    expect(labels[2].textColor, '#000000');
    expect(labels[2].memberId, 'a');
    expect(labels[2].labelType, 'member');
    expect(buildCalendarDisplayLabels(group, const []), hasLength(3));
  });

  test('所属解除後も参照を表示し再加入すると現在の名前と色を使う', () {
    final event = CalendarEventDto(
      id: 'e',
      groupId: 'g',
      labelType: 'member',
      memberId: 'm',
      title: '予定',
      startDateTime: DateTime(2026),
      endDateTime: DateTime(2026),
      isAllDay: true,
    );
    const empty = GroupDto(id: 'g', ownerId: 'o', name: '家族', members: []);
    final removed = buildCalendarDisplayLabels(
      empty,
      const [],
      events: [event],
    );
    expect(removed.last.name, '所属解除・削除済みメンバーの予定');
    expect(removed.last.isSelectable, isFalse);
    final rejoined = buildCalendarDisplayLabels(
      empty.copyWith(
        members: const [
          GroupMemberDto(
            groupId: 'g',
            memberId: 'm',
            displayName: '太郎',
            color: '#FF0000',
          ),
        ],
      ),
      const [],
      events: [event],
    );
    expect(rejoined.last.name, '太郎の予定');
    expect(rejoined.last.color, '#FF0000');
    expect(rejoined.last.isSelectable, isTrue);
  });
}
