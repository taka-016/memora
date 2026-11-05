import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';

class AuthInitializationView extends ConsumerWidget {
  const AuthInitializationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authNotifierProvider);
    if (!state.hasInitializationError) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.message, textAlign: TextAlign.center),
            TextButton(
              onPressed: () =>
                  ref.read(authNotifierProvider.notifier).retryInitialization(),
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }
}
