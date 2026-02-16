import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_dto.dart';

class DvcPointCalculationScreen extends StatelessWidget {
  final GroupDto group;
  final VoidCallback onBackPressed;

  const DvcPointCalculationScreen({
    super.key,
    required this.group,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('dvc_point_calculation_screen'),
      child: Column(
        children: [
          AppBar(
            leading: IconButton(
              key: const Key('dvc_back_button'),
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed,
            ),
            title: Text(group.name),
          ),
          const Expanded(
            child: Center(
              child: Text('DVCポイント計算画面（準備中）', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
