import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/core/formatters/japanese_era_formatter.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/presentation/shared/displays/trip_cell.dart';
import 'package:memora/core/app_logger.dart';

class _VerticalDragGestureRecognizer extends VerticalDragGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class GroupTimeline extends ConsumerStatefulWidget {
  final GroupDto groupWithMembers;
  final VoidCallback? onBackPressed;
  final Function(String groupId, int year)? onTripManagementSelected;
  final Function(VoidCallback)? onSetRefreshCallback;

  const GroupTimeline({
    super.key,
    required this.groupWithMembers,
    this.onBackPressed,
    this.onTripManagementSelected,
    this.onSetRefreshCallback,
  });

  @override
  ConsumerState<GroupTimeline> createState() => _GroupTimelineState();
}

class _GroupTimelineState extends ConsumerState<GroupTimeline> {
  late final GetTripEntriesUsecase _getTripEntriesUsecase;
  static const int _initialYearRange = 5;
  static const int _yearRangeIncrement = 5;

  late Color _borderColor;

  static const double _dataRowHeight = 100.0;
  static const double _headerRowHeight = 56.0;
  static const double _borderWidth = 1.0;

  static const double _fixedColumnWidth = 100.0;
  static const double _buttonColumnWidth = 100.0;
  static const double _yearColumnWidth = 120.0;

  static const double _resizeBottomMargin = 100.0;
  static const double _rowMinHeight = 100.0;
  static const double _rowMaxHeight = 500.0;

  int _startYearOffset = -_initialYearRange;
  int _endYearOffset = _initialYearRange;

  final ScrollController _horizontalScrollController = ScrollController();
  final GlobalKey _dataTableKey = GlobalKey();

  late List<ScrollController> _rowScrollControllers;

  bool _isSyncing = false;

  bool _isDraggingOnFixedRow = false;

  late List<double> _rowHeights;

  final Map<int, List<TripEntry>> _tripsByYear = {};

  @override
  void initState() {
    super.initState();

    _getTripEntriesUsecase = ref.read(getTripEntriesUsecaseProvider);
    final totalDataRows = 2 + widget.groupWithMembers.members.length;
    _rowHeights = List.filled(totalDataRows, _dataRowHeight);

    _rowScrollControllers = List.generate(
      totalDataRows + 1,
      (index) => ScrollController(),
    );

    for (int i = 0; i < _rowScrollControllers.length; i++) {
      final controller = _rowScrollControllers[i];
      controller.addListener(() => _syncScrollControllers(i));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentYear();
    });

    _loadTripDataForVisibleYears();

    widget.onSetRefreshCallback?.call(refreshTripData);
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
      return;
    }

    try {
      final trips = await _getTripEntriesUsecase.execute(
        widget.groupWithMembers.id,
        year,
      );
      if (mounted) {
        setState(() {
          _tripsByYear[year] = trips;
        });
      }
    } catch (e, stack) {
      logger.e(
        'GroupTimeline._loadTripDataForYear: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        setState(() {
          _tripsByYear[year] = [];
        });
      }
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

  Future<void> refreshTripData() async {
    _tripsByYear.clear();
    await _loadTripDataForVisibleYears();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _borderColor = Theme.of(context).colorScheme.outlineVariant;

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
        widget.groupWithMembers.name,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTimelineTable() {
    return Container(
      key: const Key('unified_border_table'),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFixedHeaderCell(),
              Container(
                width: _borderWidth,
                height: _headerRowHeight,
                color: _borderColor,
              ),
              Expanded(child: _buildScrollableHeaderRow()),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: () {
                return _isDraggingOnFixedRow
                    ? const NeverScrollableScrollPhysics()
                    : null;
              }(),
              child: Column(
                children: [
                  ..._buildDataRowsWithResizers(),
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
      controller: _rowScrollControllers[0],
      scrollDirection: Axis.horizontal,
      child: Container(key: _dataTableKey, child: _buildHeaderRow()),
    );
  }

  List<Widget> _buildDataRowsWithResizers() {
    final members = widget.groupWithMembers.members;
    final dataRowLabels = ['旅行', 'イベント', ...members.map((m) => m.displayName)];

    List<Widget> widgets = [];

    for (int i = 0; i < dataRowLabels.length; i++) {
      widgets.add(_buildDataRow(i, dataRowLabels[i]));
    }

    return widgets;
  }

  Widget _buildDataRow(int rowIndex, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Container(
              width: _borderWidth,
              height: _rowHeights[rowIndex],
              color: _borderColor,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _rowScrollControllers[rowIndex + 1],
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
        if (rowIndex < _rowHeights.length)
          Positioned(
            left: 0,
            bottom: -19,
            child: Listener(
              onPointerDown: (_) {
                if (mounted) {
                  setState(() {
                    _isDraggingOnFixedRow = true;
                  });
                }
              },
              onPointerUp: (_) {
                if (mounted) {
                  setState(() {
                    _isDraggingOnFixedRow = false;
                  });
                }
              },
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
                          if (mounted) {
                            setState(() {
                              _rowHeights[rowIndex] =
                                  (_rowHeights[rowIndex] + details.delta.dy)
                                      .clamp(_rowMinHeight, _rowMaxHeight);
                            });
                          }
                        };
                      }),
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeUpDown,
                  child: Container(
                    width: _fixedColumnWidth,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(0, 255, 0, 0),
                    ),
                    child: Icon(
                      Icons.drag_handle,
                      size: 40,
                      color: colorScheme.outline,
                    ),
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

        final isTripRow = rowIndex == 0;
        final isGroupEventRow = rowIndex == 1;
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
                color: isTripRow || isGroupEventRow
                    ? Colors.lightBlue.shade50
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
    final yearIndex = columnIndex - 1;
    final currentYear = DateTime.now().year;
    final selectedYear = currentYear + _startYearOffset + yearIndex;

    final trips = _tripsByYear[selectedYear] ?? [];

    return TripCell(
      trips: trips,
      availableHeight: _rowHeights[0],
      availableWidth: _yearColumnWidth,
    );
  }

  Widget _buildHeaderRow() {
    final currentYear = DateTime.now().year;
    List<Widget> cells = [];

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

    for (int i = _startYearOffset; i <= _endYearOffset; i++) {
      final year = currentYear + i;
      final eraFormatted = JapaneseEraFormatter.formatJapaneseEraFormatterYear(
        year,
      );
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
    if (mounted) {
      setState(() {
        _startYearOffset -= _yearRangeIncrement;
      });
      _loadTripDataForVisibleYears();
    }
  }

  void _showMoreFuture() {
    if (mounted) {
      setState(() {
        _endYearOffset += _yearRangeIncrement;
      });
      _loadTripDataForVisibleYears();
    }
  }

  void _syncScrollControllers(int sourceIndex) {
    if (_isSyncing) return;

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
    final primaryController = _rowScrollControllers[0];
    if (!primaryController.hasClients) return;

    final scrollViewRenderBox = context.findRenderObject() as RenderBox?;
    if (scrollViewRenderBox == null) return;

    final viewportWidth = scrollViewRenderBox.size.width;

    final yearColumnsCount = _endYearOffset - _startYearOffset + 2;
    final totalWidth =
        2 * _buttonColumnWidth + yearColumnsCount * _yearColumnWidth;

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
    final yearIndex = columnIndex - 1;
    final currentYear = DateTime.now().year;
    final selectedYear = currentYear + _startYearOffset + yearIndex;

    if (widget.onTripManagementSelected != null) {
      widget.onTripManagementSelected!(
        widget.groupWithMembers.id,
        selectedYear,
      );
    }
  }
}
