import 'package:flutter/material.dart';

class UserDrawerHeader extends StatelessWidget {
  final String email;

  const UserDrawerHeader({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(color: Colors.deepPurple),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'memora',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: 16),
          Text(
            email,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
