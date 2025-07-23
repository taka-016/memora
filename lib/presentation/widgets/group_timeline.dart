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

  // テーブルスタイル定数
  static const double _dataRowHeight = 48.0; // DataTableのデフォルト行高さ
  static const double _headerRowHeight = 56.0; // DataTableのデフォルトヘッダー高さ
  static const Color _borderColor = Colors.grey;
  static const double _borderWidth = 1.0;

  // 表示する年の範囲を管理
  int _startYearOffset = -_initialYearRange;
  int _endYearOffset = _initialYearRange;

  // 水平スクロール制御用
  final ScrollController _horizontalScrollController = ScrollController();
  final GlobalKey _dataTableKey = GlobalKey();

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
    return Container(
      key: const Key('unified_border_table'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 固定列（種類列）
          _buildFixedColumn(),
          // 列の区切り線
          _buildColumnDivider(),
          // スクロール可能な列（年の列）
          Expanded(child: _buildScrollableColumns()),
        ],
      ),
    );
  }

  Widget _buildFixedColumn() {
    final members = widget.groupWithMembers.members;

    // 固定列のデータを準備
    final rows = [
      ['種類'], // ヘッダー
      ['旅行'], // データ行
      ['イベント'],
      ...members.map((member) => [member.displayName]),
    ];

    return SizedBox(
      width: 100,
      key: const Key('fixed_column_table'),
      child: Table(
        border: TableBorder(
          left: BorderSide(color: _borderColor, width: _borderWidth),
          // right: 列区切り線と重複するため削除
          top: BorderSide(color: _borderColor, width: _borderWidth),
          bottom: BorderSide(color: _borderColor, width: _borderWidth),
          horizontalInside: BorderSide(
            color: _borderColor,
            width: _borderWidth,
          ),
        ),
        children: rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final isHeader = index == 0;
          final height = isHeader ? _headerRowHeight : _dataRowHeight;

          return TableRow(
            children: [
              Container(
                height: height,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(row[0]),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColumnDivider() {
    final members = widget.groupWithMembers.members;
    // ヘッダー高さ + データ行数（旅行・イベント + メンバー数）× データ行高さ
    final totalHeight =
        _headerRowHeight + (2 + members.length) * _dataRowHeight;

    return Container(
      key: const Key('column_divider'),
      width: _borderWidth,
      height: totalHeight,
      color: _borderColor,
    );
  }

  Widget _buildScrollableColumns() {
    final columns = _createYearColumns();
    final rows = _createTimelineRows(columns.length);

    return SingleChildScrollView(
      controller: _horizontalScrollController,
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          key: _dataTableKey,
          border: TableBorder(
            // left: 固定列との重複を避けるため削除
            right: BorderSide(color: _borderColor, width: _borderWidth),
            top: BorderSide(color: _borderColor, width: _borderWidth),
            bottom: BorderSide(color: _borderColor, width: _borderWidth),
            horizontalInside: BorderSide(
              color: _borderColor,
              width: _borderWidth,
            ),
            verticalInside: BorderSide(
              color: _borderColor,
              width: _borderWidth,
            ),
          ),
          columns: columns.skip(1).toList(), // 種類列を除外
          rows: rows
              .map(
                (row) => DataRow(cells: row.cells.skip(1).toList()), // 種類列を除外
              )
              .toList(),
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

    // DataTableの実際のサイズを取得
    final dataTableRenderBox =
        _dataTableKey.currentContext?.findRenderObject() as RenderBox?;
    if (dataTableRenderBox == null) return;

    final tableWidth = dataTableRenderBox.size.width;

    // ScrollViewのビューポート幅を取得
    final scrollViewRenderBox = context.findRenderObject() as RenderBox?;
    if (scrollViewRenderBox == null) return;

    final viewportWidth = scrollViewRenderBox.size.width;

    // 項目数を計算（種類列 + さらに表示ボタン列2つ + 年の列数）
    final totalColumns = 1 + 2 + (_endYearOffset - _startYearOffset + 1);

    // 1項目あたりの平均幅を計算
    final averageColumnWidth = tableWidth / totalColumns;

    // 現在の年が少し右にオフセットされるようにスクロール位置を計算
    // テーブル全体の中央から、ビューポート幅の半分を引き、項目幅の半分を右にオフセット
    final rightOffset = averageColumnWidth / 2;
    final scrollOffset = (tableWidth / 2) - (viewportWidth / 2) + rightOffset;

    // スクロール範囲内に調整
    final maxScrollExtent =
        _horizontalScrollController.position.maxScrollExtent;
    final targetOffset = scrollOffset.clamp(0.0, maxScrollExtent);

    _horizontalScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
