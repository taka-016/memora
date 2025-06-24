import 'package:flutter/material.dart';
import '../../application/usecases/get_current_member_usecase.dart';
import '../../application/utils/nickname_display_util.dart';
import '../../domain/entities/member.dart';

class UserDrawerHeader extends StatefulWidget {
  final GetCurrentMemberUseCase getCurrentMemberUseCase;

  const UserDrawerHeader({super.key, required this.getCurrentMemberUseCase});

  @override
  State<UserDrawerHeader> createState() => _UserDrawerHeaderState();
}

class _UserDrawerHeaderState extends State<UserDrawerHeader> {
  Member? _currentMember;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentMember();
  }

  Future<void> _loadCurrentMember() async {
    try {
      final member = await widget.getCurrentMemberUseCase.execute();
      if (mounted) {
        setState(() {
          _currentMember = member;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
          if (_isLoading)
            const Text(
              '読み込み中...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            )
          else
            Text(
              _currentMember != null
                  ? NicknameDisplayUtil.getDisplayName(_currentMember!)
                  : '名前未設定',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
        ],
      ),
    );
  }
}
