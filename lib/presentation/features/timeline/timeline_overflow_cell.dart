import 'package:flutter/material.dart';

class TimelineOverflowCell<T> extends StatelessWidget {
  final List<T> items;
  final double availableHeight;
  final double availableWidth;
  final double itemHeight;
  final EdgeInsetsGeometry padding;
  final Widget Function(T item, TextStyle textStyle) itemBuilder;
  final String Function(int remainingCount) overflowLabelBuilder;

  const TimelineOverflowCell({
    super.key,
    required this.items,
    required this.availableHeight,
    required this.availableWidth,
    required this.itemHeight,
    required this.itemBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
    this.overflowLabelBuilder = _defaultOverflowLabel,
  });

  static String _defaultOverflowLabel(int remainingCount) =>
      '…他$remainingCount件';

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container();
    }

    final textStyle = TextStyle(
      fontSize: 12.0,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return Container(
      height: availableHeight,
      width: availableWidth,
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _buildItemList(constraints, textStyle);
        },
      ),
    );
  }

  Widget _buildItemList(BoxConstraints constraints, TextStyle textStyle) {
    final availableLines = (constraints.maxHeight / itemHeight).floor();
    final remainingHeight = itemHeight / 2;

    if (availableLines <= 0) {
      return Container();
    }

    if (items.length <= availableLines) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => itemBuilder(item, textStyle)).toList(),
      );
    }

    var displayCount = ((constraints.maxHeight - remainingHeight) / itemHeight)
        .floor();
    if (displayCount < 0) {
      displayCount = 0;
    }
    if (displayCount > items.length) {
      displayCount = items.length;
    }

    final remainingCount = items.length - displayCount;
    final displayItems = items.take(displayCount).toList();
    final widgets = displayItems
        .map((item) => itemBuilder(item, textStyle))
        .toList();

    widgets.add(
      SizedBox(
        height: remainingHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(overflowLabelBuilder(remainingCount), style: textStyle),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
