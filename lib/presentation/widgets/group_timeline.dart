import 'package:flutter/material.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/utils/japanese_era.dart';

class GroupTimeline extends StatelessWidget {
  final GroupWithMembers groupWithMembers;

  // 現在の年を中央として前後何年分を表示するかの定数
  static const int _yearRange = 5;

  const GroupTimeline({super.key, required this.groupWithMembers});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('group_timeline'),
      child: Column(
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              groupWithMembers.group.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          // 年表のテーブル
          Expanded(child: _buildTimelineTable()),
        ],
      ),
    );
  }

  Widget _buildTimelineTable() {
    final columns = _createYearColumns();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: columns,
          rows: _createTimelineRows(columns.length),
        ),
      ),
    );
  }

  List<DataColumn> _createYearColumns() {
    final currentYear = DateTime.now().year;
    List<DataColumn> columns = [const DataColumn(label: Text('種類'))];

    for (int i = -_yearRange; i <= _yearRange; i++) {
      final year = currentYear + i;
      final eraFormatted = JapaneseEra.formatJapaneseEraYear(year);
      final combinedYearFormat = '$year年($eraFormatted)';
      columns.add(DataColumn(label: Text(combinedYearFormat)));
    }

    return columns;
  }

  List<DataRow> _createTimelineRows(int columnCount) {
    List<DataCell> createEmptyRowCells() {
      return List.generate(
        columnCount - 1,
        (index) => const DataCell(Text('')),
      );
    }

    return [
      DataRow(cells: [const DataCell(Text('旅行')), ...createEmptyRowCells()]),
      DataRow(cells: [const DataCell(Text('イベント')), ...createEmptyRowCells()]),
      // メンバーの行
      ...groupWithMembers.members.map(
        (member) => DataRow(
          cells: [DataCell(Text(member.displayName)), ...createEmptyRowCells()],
        ),
      ),
    ];
  }
}
