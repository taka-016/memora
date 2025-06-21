import 'package:flutter/material.dart';

class MemberSettings extends StatelessWidget {
  const MemberSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('member_settings'),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'メンバー設定',
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
