import 'package:flutter/material.dart';
import '../../domain/entities/auth_state.dart';
import '../../application/managers/auth_manager.dart';
import 'login_page.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key, required this.authManager, required this.child});

  final AuthManager authManager;
  final Widget child;

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    if (!_isInitialized) {
      await widget.authManager.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.authManager,
      builder: (context, child) {
        final authState = widget.authManager.state;

        if (!_isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        switch (authState.status) {
          case AuthStatus.loading:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.authenticated:
            return widget.child;
          case AuthStatus.unauthenticated:
            return LoginPage(authManager: widget.authManager);
        }
      },
    );
  }
}
