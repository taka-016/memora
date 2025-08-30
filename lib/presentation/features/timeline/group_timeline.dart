import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/get_trip_entries_usecase.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/infrastructure/repositories/firestore_trip_entry_repository.dart';
import 'package:memora/application/utils/japanese_era.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/presentation/shared/displays/trip_cell.dart';

class _VerticalDragGestureRecognizer extends VerticalDragGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class GroupTimeline extends StatefulWidget {
  final GroupWithMembers groupWithMembers;
  final VoidCallback? onBackPressed;
  final Function(String groupId, int year)? onTripManagementSelected;
  final TripEntryRepository? tripEntryRepository;

  const GroupTimeline({
    super.key,
    required this.groupWithMembers,
    this.tripEntryRepository,
    this.onBackPressed,
    this.onTripManagementSelected,
  });

  @override
  State<GroupTimeline> createState() => _GroupTimelineState();
}

class _GroupTimelineState extends State<GroupTimeline> {
  late final GetTripEntriesUsecase _getTripEntriesUsecase;
  // 現在の年を中央として前後何年分を表示するかの定数
  static const int _initialYearRange = 5;
  static const int _yearRangeIncrement = 5;

  // テーブルスタイル定数
  static const double _dataRowHeight = 100.0; // DataTableのデフォルト行高さ
  static const double _headerRowHeight = 56.0; // DataTableのデフォルトヘッダー高さ
  static const Color _borderColor = Colors.grey;
  static const double _borderWidth = 1.0;

  // 列幅定数
  static const double _fixedColumnWidth = 100.0; // 固定列の幅
  static const double _buttonColumnWidth = 100.0; // ボタン列の幅
  static const double _yearColumnWidth = 120.0; // 年列の幅

  // リサイズ関連定数
  static const double _resizeBottomMargin = 100.0; // 最終行のリサイズ操作のための余白
  static const double _rowMinHeight = 100.0; // 行の最小高さ
  static const double _rowMaxHeight = 500.0; // 行の最大高さ

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

  // 旅行データをキャッシュするMap（年 -> 旅行リスト）
  final Map<int, List<TripEntry>> _tripsByYear = {};

  @override
  void initState() {
    super.initState();

    // 注入されたリポジトリまたはデフォルトのFirestoreリポジトリを使用
    final tripEntryRepository =
        widget.tripEntryRepository ?? FirestoreTripEntryRepository();

    // ユースケースを初期化
    _getTripEntriesUsecase = GetTripEntriesUsecase(tripEntryRepository);
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

    // 初期表示される年の旅行データを取得
    _loadTripDataForVisibleYears();
  }

  Future<void> _loadTripDataForVisibleYears() async {
    final currentYear = DateTime.now().year;
    for (int offset = _startYearOffset; offset <= _endYearOffset; offset++) {
      final year = currentYear + offset;
      await _loadTripDataForYear(year);
    }
  }

  Future<void> _loadTripDataForYear(int year) async {
    if (_tripsByYear.containsKey(year)) {
      return; // 既に読み込み済み
    }

    try {
      final trips = await _getTripEntriesUsecase.execute(
        widget.groupWithMembers.group.id,
        year,
      );
      setState(() {
        _tripsByYear[year] = trips;
      });
    } catch (e) {
      // エラーハンドリング（空のリストを設定）
      setState(() {
        _tripsByYear[year] = [];
      });
    }
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
          _buildHeader(),
          Expanded(child: _buildTimelineTable()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          if (widget.onBackPressed != null) _buildBackButton(),
          _buildGroupTitle(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      left: 0,
      top: 0,
      child: IconButton(
        key: const Key('back_button'),
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onBackPressed,
      ),
    );
  }

  Widget _buildGroupTitle() {
    return Center(
      child: Text(
        widget.groupWithMembers.group.name,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
          // データ行
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ..._buildDataRowsWithResizers(),
                  // 最終行のリサイズ操作のための余白
                  SizedBox(height: _resizeBottomMargin),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeaderCell() {
    return Container(
      width: _fixedColumnWidth,
      height: _headerRowHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: _borderColor, width: _borderWidth),
          top: BorderSide(color: _borderColor, width: _borderWidth),
          bottom: BorderSide(color: _borderColor, width: _borderWidth),
        ),
      ),
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
    }

    return widgets;
  }

  Widget _buildDataRow(int rowIndex, String label) {
    return Stack(
      children: [
        // メインの行
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 固定列のデータセル
            Container(
              key: Key('fixed_row_$rowIndex'),
              width: _fixedColumnWidth,
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
                controller:
                    _rowScrollControllers[rowIndex + 1], // データ行用（ヘッダー行の次から）
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  key: Key('scrollable_row_$rowIndex'),
                  height: _rowHeights[rowIndex],
                  child: _buildScrollableDataCells(rowIndex),
                ),
              ),
            ),
          ],
        ),
        // リサイザーアイコン
        if (rowIndex < _rowHeights.length)
          Positioned(
            left: 0, // 固定列の中央（100px / 2 - アイコン幅の半分）
            bottom: -19, // 境界線の中央に配置
            child: RawGestureDetector(
              key: Key('row_resizer_icon_$rowIndex'),
              gestures: {
                _VerticalDragGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      _VerticalDragGestureRecognizer
                    >(() => _VerticalDragGestureRecognizer(), (
                      _VerticalDragGestureRecognizer instance,
                    ) {
                      instance.onUpdate = (details) {
                        setState(() {
                          _rowHeights[rowIndex] =
                              (_rowHeights[rowIndex] + details.delta.dy).clamp(
                                _rowMinHeight,
                                _rowMaxHeight,
                              );
                        });
                      };
                    }),
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: Container(
                  width: _fixedColumnWidth,
                  height: 50,
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: const Icon(
                    Icons.drag_handle,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
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
            ? _buttonColumnWidth
            : _yearColumnWidth;

        // 旅行行（rowIndex == 0）の場合のみタップ可能にする
        final isTripRow = rowIndex == 0;
        final isYearColumn = columnIndex != 0 && columnIndex != columnCount - 1;

        return SizedBox(
          width: width,
          height: _rowHeights[rowIndex],
          child: GestureDetector(
            onTap: isTripRow && isYearColumn
                ? () => _onTripCellTapped(columnIndex)
                : null,
            child: Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _borderColor, width: _borderWidth),
                  right: BorderSide(color: _borderColor, width: _borderWidth),
                ),
                // 旅行セルの場合、ホバー効果を追加
                color: isTripRow && isYearColumn
                    ? Colors.blue.shade50
                    : Colors.transparent,
              ),
              child: isTripRow && isYearColumn
                  ? _buildTripCellContent(columnIndex)
                  : const Text(''),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTripCellContent(int columnIndex) {
    // 年を特定する
    final yearIndex = columnIndex - 1; // 最初の列はボタン列なので-1
    final currentYear = DateTime.now().year;
    final selectedYear = currentYear + _startYearOffset + yearIndex;

    // この年の旅行データを取得
    final trips = _tripsByYear[selectedYear] ?? [];

    return TripCell(
      trips: trips,
      availableHeight: _rowHeights[0], // 旅行行の高さ
      availableWidth: _yearColumnWidth,
    );
  }

  Widget _buildHeaderRow() {
    final currentYear = DateTime.now().year;
    List<Widget> cells = [];

    // 「さらに表示」ボタンを先頭に追加
    cells.add(
      Container(
        width: _buttonColumnWidth,
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
          width: _yearColumnWidth,
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
        width: _buttonColumnWidth,
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
    _loadTripDataForVisibleYears();
  }

  void _showMoreFuture() {
    setState(() {
      _endYearOffset += _yearRangeIncrement;
    });
    _loadTripDataForVisibleYears();
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

    // 1項目あたりの平均幅を計算（ボタン列、年列）
    final yearColumnsCount = _endYearOffset - _startYearOffset + 2;
    final totalWidth =
        2 * _buttonColumnWidth + yearColumnsCount * _yearColumnWidth;

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

  void _onTripCellTapped(int columnIndex) {
    // 年を特定する
    final yearIndex = columnIndex - 1; // 最初の列はボタン列なので-1
    final currentYear = DateTime.now().year;
    final selectedYear = currentYear + _startYearOffset + yearIndex;

    // 旅行管理ウィジェットに遷移
    if (widget.onTripManagementSelected != null) {
      widget.onTripManagementSelected!(
        widget.groupWithMembers.group.id,
        selectedYear,
      );
    }
  }
}
