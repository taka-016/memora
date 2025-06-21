import 'package:flutter/material.dart';

class GroupTimeline extends StatelessWidget {
  const GroupTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('group_timeline'),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'グループ年表',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text('今後実装予定', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
