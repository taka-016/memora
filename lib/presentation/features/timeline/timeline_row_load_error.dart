import 'package:flutter/material.dart';

class TimelineRowLoadError extends StatelessWidget {
  const TimelineRowLoadError({
    super.key,
    required this.retryButtonKey,
    required this.onRetry,
  });

  final Key retryButtonKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        key: retryButtonKey,
        onPressed: onRetry,
        child: const Text('再試行'),
      ),
    );
  }
}
