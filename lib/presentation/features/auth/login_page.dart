import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Memoraへようこそ',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Googleアカウントでログインして利用を開始できます。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (authState.message.isNotEmpty) ...[
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: authState.isInfoMessage
                              ? scheme.tertiaryContainer
                              : scheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                authState.message,
                                style: TextStyle(
                                  color: authState.isInfoMessage
                                      ? scheme.onTertiaryContainer
                                      : scheme.onErrorContainer,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'メッセージを閉じる',
                              icon: const Icon(Icons.close),
                              onPressed: () => ref
                                  .read(authNotifierProvider.notifier)
                                  .clearError(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    key: const Key('login_button'),
                    onPressed: authState.isLoading
                        ? null
                        : () => ref.read(authNotifierProvider.notifier).login(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1F1F1F),
                      side: const BorderSide(color: Color(0xFF747775)),
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    icon: Image.asset(
                      'assets/images/google_g.png',
                      width: 20,
                      height: 20,
                      excludeFromSemantics: true,
                    ),
                    label: const Text('Googleでログイン'),
                  ),
                  if (authState.isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
