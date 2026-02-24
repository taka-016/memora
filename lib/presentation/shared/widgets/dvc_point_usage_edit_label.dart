import 'package:flutter/material.dart';

class DvcPointUsageEditLabel extends StatelessWidget {
  final VoidCallback? onPressed;

  const DvcPointUsageEditLabel({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DVC'),
        const SizedBox(width: 8),
        InkWell(
          key: const Key('timeline_dvc_point_usage_edit_button'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.edit, size: 16),
          ),
        ),
      ],
    );
  }
}
