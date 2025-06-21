import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/managers/auth_manager.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('settings'),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings, size: 100, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '設定',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '今後実装予定',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                final authManager = Provider.of<AuthManager>(
                  context,
                  listen: false,
                );
                authManager.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ログアウト（テスト用）'),
            ),
          ],
        ),
      ),
    );
  }
}
