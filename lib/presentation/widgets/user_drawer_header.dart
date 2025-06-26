import 'package:flutter/material.dart';
import '../../application/utils/nickname_display_util.dart';
import '../../domain/entities/member.dart';

class UserDrawerHeader extends StatelessWidget {
  final Member? member;

  const UserDrawerHeader({super.key, required this.member});

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
            member != null
                ? NicknameDisplayUtil.getDisplayName(member!)
                : '名前未設定',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
