import 'package:flutter/material.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/utils/japanese_era.dart';

class GroupTimeline extends StatelessWidget {
  final GroupWithMembers groupWithMembers;

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
    // 現在の年を取得し、西暦と和暦を組み合わせてフォーマット
    final currentYear = DateTime.now().year;
    final eraFormatted = JapaneseEra.formatJapaneseEraYear(currentYear);
    final combinedYearFormat = '$currentYear年($eraFormatted)';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            const DataColumn(label: Text('種類')),
            DataColumn(label: Text(combinedYearFormat)),
          ],
          rows: [
            const DataRow(cells: [DataCell(Text('旅行')), DataCell(Text(''))]),
            const DataRow(cells: [DataCell(Text('イベント')), DataCell(Text(''))]),
            // メンバーの行
            ...groupWithMembers.members.map(
              (member) => DataRow(
                cells: [
                  DataCell(Text(member.displayName)),
                  const DataCell(Text('')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
