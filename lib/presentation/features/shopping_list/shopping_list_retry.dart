import 'package:flutter/material.dart';

class ShoppingListRetry extends StatelessWidget {
  const ShoppingListRetry({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        TextButton(onPressed: onRetry, child: const Text('再読み込み')),
      ],
    ),
  );
}
