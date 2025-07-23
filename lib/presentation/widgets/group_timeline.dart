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

  // 各行のScrollControllerを管理
  late List<ScrollController> _rowScrollControllers;

  // スクロール同期中かどうかを追跡
  bool _isSyncing = false;

  // 行の高さを管理するList
  late List<double> _rowHeights;

  @override
  void initState() {
    super.initState();
    // 行の高さを初期化（ヘッダー行を除く）
    final totalDataRows =
        2 + widget.groupWithMembers.members.length; // 旅行 + イベント + メンバー数
    _rowHeights = List.filled(totalDataRows, _dataRowHeight);

    // 各行用のScrollControllerを初期化（ヘッダー用1つ + データ行数）
    _rowScrollControllers = List.generate(
      totalDataRows + 1,
      (index) => ScrollController(),
    );

    // スクロール同期のリスナーを設定
    for (int i = 0; i < _rowScrollControllers.length; i++) {
      final controller = _rowScrollControllers[i];
      controller.addListener(() => _syncScrollControllers(i));
    }

    // 初期表示時に現在の年が中央に表示されるようにスクロール位置を調整
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentYear();
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    for (final controller in _rowScrollControllers) {
      controller.dispose();
    }
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
      child: Column(
        children: [
          // ヘッダー行
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 固定ヘッダー列
              _buildFixedHeaderCell(),
              // 列の区切り線
              Container(
                width: _borderWidth,
                height: _headerRowHeight,
                color: _borderColor,
              ),
              // スクロール可能なヘッダー列
              Expanded(child: _buildScrollableHeaderRow()),
            ],
          ),
          // データ行とリサイザー
          Expanded(child: Column(children: _buildDataRowsWithResizers())),
        ],
      ),
    );
  }

  Widget _buildFixedHeaderCell() {
    return Container(
      width: 100,
      height: _headerRowHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: _borderColor, width: _borderWidth),
          top: BorderSide(color: _borderColor, width: _borderWidth),
          bottom: BorderSide(color: _borderColor, width: _borderWidth),
        ),
      ),
      child: const Text('種類'),
    );
  }

  Widget _buildScrollableHeaderRow() {
    return SingleChildScrollView(
      controller: _rowScrollControllers[0], // ヘッダー行用
      scrollDirection: Axis.horizontal,
      child: Container(key: _dataTableKey, child: _buildHeaderRow()),
    );
  }

  List<Widget> _buildDataRowsWithResizers() {
    final members = widget.groupWithMembers.members;
    final dataRowLabels = ['旅行', 'イベント', ...members.map((m) => m.displayName)];

    List<Widget> widgets = [];

    for (int i = 0; i < dataRowLabels.length; i++) {
      // データ行
      widgets.add(_buildDataRow(i, dataRowLabels[i]));

      // リサイザー（最後の行以外）
      if (i < dataRowLabels.length - 1) {
        widgets.add(_buildRowResizer(i));
      }
    }

    return widgets;
  }

  Widget _buildDataRow(int rowIndex, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 固定列のデータセル
        Container(
          key: Key('fixed_row_$rowIndex'),
          width: 100,
          height: _rowHeights[rowIndex],
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: _borderColor, width: _borderWidth),
              bottom: BorderSide(color: _borderColor, width: _borderWidth),
            ),
          ),
          child: Text(label),
        ),
        // 列の区切り線
        Container(
          width: _borderWidth,
          height: _rowHeights[rowIndex],
          color: _borderColor,
        ),
        // スクロール可能な列
        Expanded(
          child: SingleChildScrollView(
            controller: _rowScrollControllers[rowIndex + 1], // データ行用（ヘッダー行の次から）
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              key: Key('scrollable_row_$rowIndex'),
              height: _rowHeights[rowIndex],
              child: _buildScrollableDataCells(rowIndex),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableDataCells(int rowIndex) {
    final columnCount = 2 + (_endYearOffset - _startYearOffset + 1);

    return Row(
      children: List.generate(columnCount, (columnIndex) {
        final width = columnIndex == 0 || columnIndex == columnCount - 1
            ? 100.0
            : 120.0;
        return SizedBox(
          width: width,
          height: _rowHeights[rowIndex],
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _borderColor, width: _borderWidth),
                right: BorderSide(color: _borderColor, width: _borderWidth),
              ),
            ),
            child: const Text(''),
          ),
        );
      }),
    );
  }

  Widget _buildRowResizer(int rowIndex) {
    return SizedBox(
      height: 12,
      child: Row(
        children: [
          // 固定列の境界線上にリサイザー
          SizedBox(
            width: 100,
            child: GestureDetector(
              key: Key('row_resizer_$rowIndex'),
              onPanUpdate: (details) {
                setState(() {
                  _rowHeights[rowIndex] =
                      (_rowHeights[rowIndex] + details.delta.dy).clamp(
                        50.0,
                        250.0,
                      );
                });
              },
              child: Container(
                height: 12,
                color: const Color.fromARGB(255, 255, 227, 227),
              ),
            ),
          ),
          // スクロール可能領域のリサイザー
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _rowHeights[rowIndex] =
                      (_rowHeights[rowIndex] + details.delta.dy).clamp(
                        50.0,
                        250.0,
                      );
                });
              },
              child: Container(
                height: 12,
                color: const Color.fromARGB(255, 255, 227, 227),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    final currentYear = DateTime.now().year;
    List<Widget> cells = [];

    // 「さらに表示」ボタンを先頭に追加
    cells.add(
      Container(
        width: 100,
        height: _headerRowHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: _borderColor, width: _borderWidth),
            bottom: BorderSide(color: _borderColor, width: _borderWidth),
            right: BorderSide(color: _borderColor, width: _borderWidth),
          ),
        ),
        child: TextButton(
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
      cells.add(
        Container(
          width: 120,
          height: _headerRowHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _borderColor, width: _borderWidth),
              bottom: BorderSide(color: _borderColor, width: _borderWidth),
              right: BorderSide(color: _borderColor, width: _borderWidth),
            ),
          ),
          child: Text(combinedYearFormat),
        ),
      );
    }

    // 「さらに表示」ボタンを末尾に追加
    cells.add(
      Container(
        width: 100,
        height: _headerRowHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: _borderColor, width: _borderWidth),
            bottom: BorderSide(color: _borderColor, width: _borderWidth),
            right: BorderSide(color: _borderColor, width: _borderWidth),
          ),
        ),
        child: TextButton(
          key: const Key('show_more_future'),
          onPressed: _showMoreFuture,
          child: const Text('さらに表示'),
        ),
      ),
    );

    return Row(children: cells);
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

  void _syncScrollControllers(int sourceIndex) {
    if (_isSyncing) return; // 無限ループを防ぐ

    final sourceController = _rowScrollControllers[sourceIndex];
    if (!sourceController.hasClients) return;

    _isSyncing = true;
    final targetOffset = sourceController.offset;

    for (int i = 0; i < _rowScrollControllers.length; i++) {
      if (i != sourceIndex && _rowScrollControllers[i].hasClients) {
        _rowScrollControllers[i].jumpTo(targetOffset);
      }
    }

    _isSyncing = false;
  }

  void _scrollToCurrentYear() {
    // 最初のScrollController（ヘッダー行）のみを使用
    final primaryController = _rowScrollControllers[0];
    if (!primaryController.hasClients) return;

    final scrollViewRenderBox = context.findRenderObject() as RenderBox?;
    if (scrollViewRenderBox == null) return;

    final viewportWidth = scrollViewRenderBox.size.width;

    // 1項目あたりの平均幅を計算（ボタン列：100px、年列：120px）
    final buttonColumnWidth = 100.0;
    final yearColumnWidth = 120.0;
    final yearColumnsCount = _endYearOffset - _startYearOffset + 1;
    final totalWidth =
        2 * buttonColumnWidth + yearColumnsCount * yearColumnWidth;

    // 現在の年が中央に来るようにスクロール位置を計算
    final scrollOffset = (totalWidth / 2) - (viewportWidth / 2);

    final maxScrollExtent = primaryController.position.maxScrollExtent;
    final targetOffset = scrollOffset.clamp(0.0, maxScrollExtent);

    primaryController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
