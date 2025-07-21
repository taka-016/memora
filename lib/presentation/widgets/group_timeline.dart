import 'package:flutter/material.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/utils/japanese_era.dart';

class GroupTimeline extends StatefulWidget {
  final GroupWithMembers groupWithMembers;

  const GroupTimeline({super.key, required this.groupWithMembers});

  @override
  State<GroupTimeline> createState() => _GroupTimelineState();
}

class _GroupTimelineState extends State<GroupTimeline> {
  // 現在の年を中央として前後何年分を表示するかの定数
  static const int _initialYearRange = 5;
  static const int _yearRangeIncrement = 5;

  // 表示する年の範囲を管理
  int _startYearOffset = -_initialYearRange;
  int _endYearOffset = _initialYearRange;

  // 水平スクロール制御用
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 初期表示時に現在の年が中央に表示されるようにスクロール位置を調整
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentYear();
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

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
              widget.groupWithMembers.group.name,
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
      controller: _horizontalScrollController,
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

    // 「さらに表示」ボタンを先頭に追加
    columns.add(
      DataColumn(
        label: TextButton(
          key: const Key('show_more_past'),
          onPressed: _showMorePast,
          child: const Text('さらに表示'),
        ),
      ),
    );

    // 年の列を追加
    for (int i = _startYearOffset; i <= _endYearOffset; i++) {
      final year = currentYear + i;
      final eraFormatted = JapaneseEra.formatJapaneseEraYear(year);
      final combinedYearFormat = '$year年($eraFormatted)';
      columns.add(DataColumn(label: Text(combinedYearFormat)));
    }

    // 「さらに表示」ボタンを末尾に追加
    columns.add(
      DataColumn(
        label: TextButton(
          key: const Key('show_more_future'),
          onPressed: _showMoreFuture,
          child: const Text('さらに表示'),
        ),
      ),
    );

    return columns;
  }

  List<DataRow> _createTimelineRows(int columnCount) {
    List<DataCell> createEmptyRowCells() {
      // 種類列を除いたセル数で空のセルを作成
      return List.generate(
        columnCount - 1,
        (index) => const DataCell(Text('')),
      );
    }

    return [
      DataRow(cells: [const DataCell(Text('旅行')), ...createEmptyRowCells()]),
      DataRow(cells: [const DataCell(Text('イベント')), ...createEmptyRowCells()]),
      // メンバーの行
      ...widget.groupWithMembers.members.map(
        (member) => DataRow(
          cells: [DataCell(Text(member.displayName)), ...createEmptyRowCells()],
        ),
      ),
    ];
  }

  void _showMorePast() {
    setState(() {
      _startYearOffset -= _yearRangeIncrement;
    });
  }

  void _showMoreFuture() {
    setState(() {
      _endYearOffset += _yearRangeIncrement;
    });
  }

  void _scrollToCurrentYear() {
    if (!_horizontalScrollController.hasClients) return;

    // DataTableの各列の推定幅を使用して中央位置を計算
    const double estimatedColumnWidth = 120.0; // 年列の推定幅
    const double firstColumnWidth = 80.0; // 「種類」列の推定幅
    const double buttonColumnWidth = 100.0; // 「さらに表示」ボタン列の推定幅

    // 現在の年は中央（オフセット0）の位置にある
    // 「種類」列 + 「さらに表示」ボタン列 + 過去の年の列数分をスキップして中央の年にスクロール
    final double scrollOffset =
        firstColumnWidth +
        buttonColumnWidth +
        (_initialYearRange * estimatedColumnWidth) -
        (estimatedColumnWidth / 2);

    _horizontalScrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
