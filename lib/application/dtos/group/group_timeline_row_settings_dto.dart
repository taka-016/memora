import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/core/enums/group_timeline_row_type.dart';

export 'package:memora/core/enums/group_timeline_row_type.dart';

class GroupTimelineRowSettingDto extends Equatable {
  const GroupTimelineRowSettingDto({
    required this.rowId,
    required this.rowType,
    this.targetId,
    required this.orderIndex,
    required this.isVisible,
  });

  static const String tripRowId = 'trip';
  static const String groupEventRowId = 'group_event';
  static const String dvcRowId = 'dvc';

  final String rowId;
  final GroupTimelineRowType rowType;
  final String? targetId;
  final int orderIndex;
  final bool isVisible;

  static String memberRowId(String memberId) => 'member:$memberId';

  GroupTimelineRowSettingDto copyWith({
    String? rowId,
    GroupTimelineRowType? rowType,
    String? targetId,
    int? orderIndex,
    bool? isVisible,
  }) {
    return GroupTimelineRowSettingDto(
      rowId: rowId ?? this.rowId,
      rowType: rowType ?? this.rowType,
      targetId: targetId ?? this.targetId,
      orderIndex: orderIndex ?? this.orderIndex,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  List<Object?> get props => [rowId, rowType, targetId, orderIndex, isVisible];
}

class GroupTimelineRowSettingsDto extends Equatable {
  const GroupTimelineRowSettingsDto({
    required this.groupId,
    required this.rows,
  });

  final String groupId;
  final List<GroupTimelineRowSettingDto> rows;

  static GroupTimelineRowSettingsDto defaultsForGroup(GroupDto group) {
    var orderIndex = 0;
    return GroupTimelineRowSettingsDto(
      groupId: group.id,
      rows: [
        GroupTimelineRowSettingDto(
          rowId: GroupTimelineRowSettingDto.tripRowId,
          rowType: GroupTimelineRowType.trip,
          orderIndex: orderIndex++,
          isVisible: true,
        ),
        GroupTimelineRowSettingDto(
          rowId: GroupTimelineRowSettingDto.groupEventRowId,
          rowType: GroupTimelineRowType.groupEvent,
          orderIndex: orderIndex++,
          isVisible: true,
        ),
        GroupTimelineRowSettingDto(
          rowId: GroupTimelineRowSettingDto.dvcRowId,
          rowType: GroupTimelineRowType.dvc,
          orderIndex: orderIndex++,
          isVisible: true,
        ),
        for (final member in group.members)
          GroupTimelineRowSettingDto(
            rowId: GroupTimelineRowSettingDto.memberRowId(member.memberId),
            rowType: GroupTimelineRowType.member,
            targetId: member.memberId,
            orderIndex: orderIndex++,
            isVisible: true,
          ),
      ],
    );
  }

  GroupTimelineRowSettingsDto mergeWithDefaultRows(GroupDto group) {
    final defaultSettings = defaultsForGroup(group);
    final defaultRowsById = {
      for (final row in defaultSettings.rows) row.rowId: row,
    };
    final savedRows =
        rows.where((row) => defaultRowsById.containsKey(row.rowId)).toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final savedRowIds = savedRows.map((row) => row.rowId).toSet();
    final mergedRows = [
      ...savedRows,
      ...defaultSettings.rows.where((row) => !savedRowIds.contains(row.rowId)),
    ];

    return GroupTimelineRowSettingsDto(groupId: group.id, rows: mergedRows);
  }

  @override
  List<Object?> get props => [groupId, rows];
}
