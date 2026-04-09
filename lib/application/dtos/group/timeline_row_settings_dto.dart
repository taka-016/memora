import 'package:equatable/equatable.dart';

class TimelineRowSettingDto extends Equatable {
  const TimelineRowSettingDto({
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

class TimelineRowSettingsDto extends Equatable {
  const TimelineRowSettingsDto({required this.groupId, required this.rows});

  factory TimelineRowSettingsDto.defaults({
    required String groupId,
    required List<String> memberIds,
  }) {
    final rowIds = [
      'trip',
      'group_event',
      'dvc',
      ...memberIds.map((memberId) => 'member:$memberId'),
    ];

    return TimelineRowSettingsDto(
      groupId: groupId,
      rows: [
        for (final indexedRowId in rowIds.indexed)
          TimelineRowSettingDto(
            rowId: indexedRowId.$2,
            isVisible: true,
            orderIndex: indexedRowId.$1,
          ),
      ],
    );
  }

  final String groupId;
  final List<TimelineRowSettingDto> rows;

  @override
  List<Object?> get props => [groupId, rows];
}
