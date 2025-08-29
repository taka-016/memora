import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/value-objects/auth_state.dart';
import '../../../application/managers/auth_manager.dart';
import 'login_page.dart';

class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authManagerProvider);

    switch (authState.status) {
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return child;
      case AuthStatus.unauthenticated:
        return const LoginPage();
    }
  }
}
