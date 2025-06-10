import 'package:flutter/material.dart';

class PinDetailModal extends StatelessWidget {
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;

  const PinDetailModal({super.key, this.onSave, this.onDelete, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose ?? () => Navigator.of(context).pop(),
          ),
        ),
        Positioned(
          bottom: 32,
          left: 32,
          right: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(onPressed: onDelete, child: const Text('削除')),
              ElevatedButton(onPressed: onSave, child: const Text('保存')),
            ],
          ),
        ),
      ],
    );
  }
}
