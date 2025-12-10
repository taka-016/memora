import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/domain/value_objects/auth_state.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'signup_page.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final obscurePassword = useState(true);

    Future<void> login() async {
      if (formKey.currentState?.validate() ?? false) {
        await ref
            .read(authNotifierProvider.notifier)
            .login(
              email: emailController.text.trim(),
              password: passwordController.text,
            );
        final authState = ref.read(authNotifierProvider);
        if (context.mounted && authState.isAuthenticated) {
          TextInput.finishAutofillContext();
        }
      }
    }

    void navigateToSignup() {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const SignupPage()));
    }

    Widget buildMessageContainer(AuthState authState) {
      final isInfo = authState.messageType == MessageType.info;
      final color = isInfo ? Colors.green : Colors.red;

      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: color.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.shade300),
        ),
        child: Row(
          children: [
            Icon(
              isInfo ? Icons.check_circle : Icons.error,
              color: color.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                authState.message,
                style: TextStyle(color: color.shade700),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: color.shade700),
              onPressed: () {
                ref.read(authNotifierProvider.notifier).clearError();
              },
              tooltip: 'エラーを閉じる',
            ),
          ],
        ),
      );
    }

    Widget buildEmailField() {
      return TextFormField(
        key: const Key('email_field'),
        controller: emailController,
        decoration: const InputDecoration(
          labelText: 'メールアドレス',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'メールアドレスを入力してください';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return '正しいメールアドレスを入力してください';
          }
          return null;
        },
      );
    }

    Widget buildPasswordToggleButton() {
      return IconButton(
        icon: Icon(
          obscurePassword.value ? Icons.visibility : Icons.visibility_off,
        ),
        onPressed: () {
          obscurePassword.value = !obscurePassword.value;
        },
      );
    }

    Widget buildPasswordField() {
      return TextFormField(
        key: const Key('password_field'),
        controller: passwordController,
        decoration: InputDecoration(
          labelText: 'パスワード',
          border: const OutlineInputBorder(),
          suffixIcon: buildPasswordToggleButton(),
        ),
        obscureText: obscurePassword.value,
        autofillHints: const [AutofillHints.password],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'パスワードを入力してください';
          }
          return null;
        },
      );
    }

    Widget buildLoginButton() {
      return ElevatedButton(
        key: const Key('login_button'),
        onPressed: login,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('ログイン', style: TextStyle(fontSize: 16)),
      );
    }

    Widget buildSignupLink() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('アカウントをお持ちでない方'),
          TextButton(
            key: const Key('signup_link'),
            onPressed: navigateToSignup,
            child: const Text('新規登録'),
          ),
        ],
      );
    }

    Widget buildLoadingIndicator() {
      return const Center(child: CircularProgressIndicator());
    }

    Widget buildFormContent(AuthState authState) {
      return AutofillGroup(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (authState.status == AuthStatus.loading)
                buildLoadingIndicator()
              else ...[
                if (authState.message.isNotEmpty)
                  buildMessageContainer(authState),
                buildEmailField(),
                const SizedBox(height: 16),
                buildPasswordField(),
                const SizedBox(height: 24),
                buildLoginButton(),
                const SizedBox(height: 32),
                buildSignupLink(),
              ],
            ],
          ),
        ),
      );
    }

    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: buildFormContent(authState),
      ),
    );
  }
}
