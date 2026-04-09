import 'package:equatable/equatable.dart';
import 'package:memora/core/enums/group_timeline_row_type.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

export 'package:memora/core/enums/group_timeline_row_type.dart';

class GroupTimelineRowSetting extends Equatable {
  const GroupTimelineRowSetting({
    required this.rowId,
    required this.rowType,
    this.targetId,
    required this.orderIndex,
    required this.isVisible,
  });

  final String rowId;
  final GroupTimelineRowType rowType;
  final String? targetId;
  final int orderIndex;
  final bool isVisible;

  GroupTimelineRowSetting copyWith({
    String? rowId,
    GroupTimelineRowType? rowType,
    String? targetId,
    int? orderIndex,
    bool? isVisible,
  }) {
    return GroupTimelineRowSetting(
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

class GroupTimelineRowSettings extends Equatable {
  GroupTimelineRowSettings({
    required this.groupId,
    required List<GroupTimelineRowSetting> rows,
  }) : rows = List.unmodifiable(rows) {
    final rowIds = <String>{};
    for (final row in rows) {
      if (row.rowId.isEmpty) {
        throw ValidationException('行IDは必須です');
      }
      if (!rowIds.add(row.rowId)) {
        throw ValidationException('行IDが重複しています: ${row.rowId}');
      }
    }
  }

  final String groupId;
  final List<GroupTimelineRowSetting> rows;

  GroupTimelineRowSettings copyWith({
    String? groupId,
    List<GroupTimelineRowSetting>? rows,
  }) {
    return GroupTimelineRowSettings(
      groupId: groupId ?? this.groupId,
      rows: rows ?? this.rows,
    );
  }

  @override
  List<Object?> get props => [groupId, rows];
}
