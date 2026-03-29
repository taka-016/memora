import 'package:flutter/material.dart';

class GroupEventCell extends StatelessWidget {
  const GroupEventCell({
    super.key,
    required this.memo,
    required this.availableHeight,
    required this.availableWidth,
  });

  final String memo;
  final double availableHeight;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final trimmedMemo = memo.trim();
    if (trimmedMemo.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxLines = (availableHeight / 20).floor().clamp(1, 20);

    return SizedBox(
      width: availableWidth,
      height: availableHeight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          trimmedMemo,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
