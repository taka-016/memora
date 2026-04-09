import 'package:equatable/equatable.dart';

class TimelineRowSetting extends Equatable {
  const TimelineRowSetting({
    required this.rowId,
    required this.isVisible,
    required this.orderIndex,
  });

  final String rowId;
  final bool isVisible;
  final int orderIndex;

  @override
  List<Object?> get props => [rowId, isVisible, orderIndex];
}

class TimelineRowSettings extends Equatable {
  TimelineRowSettings({
    required this.groupId,
    required List<TimelineRowSetting> rows,
  }) : rows = List.unmodifiable(rows) {
    final rowIds = <String>{};
    for (final row in rows) {
      if (!rowIds.add(row.rowId)) {
        throw ArgumentError('rowIdが重複しています: ${row.rowId}');
      }
    }
  }

  factory TimelineRowSettings.defaults({
    required String groupId,
    required List<String> memberIds,
  }) {
    final rowIds = [
      'trip',
      'group_event',
      'dvc',
      ...memberIds.map((memberId) => 'member:$memberId'),
    ];

    return TimelineRowSettings(
      groupId: groupId,
      rows: [
        for (final indexedRowId in rowIds.indexed)
          TimelineRowSetting(
            rowId: indexedRowId.$2,
            isVisible: true,
            orderIndex: indexedRowId.$1,
          ),
      ],
    );
  }

  final String groupId;
  final List<TimelineRowSetting> rows;

  @override
  List<Object?> get props => [groupId, rows];
}
