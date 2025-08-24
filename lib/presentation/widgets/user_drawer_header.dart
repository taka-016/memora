import 'package:flutter/material.dart';

class UserDrawerHeader extends StatelessWidget {
  final String email;

  const UserDrawerHeader({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: _buildDecoration(context),
      child: _buildContent(context),
    );
  }

  BoxDecoration _buildDecoration(BuildContext context) {
    return BoxDecoration(color: Theme.of(context).colorScheme.primary);
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(context),
        const SizedBox(height: 16),
        _buildEmail(context),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      'memora',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimary,
        fontSize: 24,
      ),
    );
  }

  Widget _buildEmail(BuildContext context) {
    return Text(
      email,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
        fontSize: 16,
      ),
    );
  }
}
