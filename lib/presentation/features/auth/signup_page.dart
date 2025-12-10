import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/domain/value_objects/auth_state.dart';
import 'package:memora/core/validators/password_validator.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';

class SignupPage extends HookConsumerWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final obscurePassword = useState(true);
    final obscureConfirmPassword = useState(true);

    Future<void> signup() async {
      if (formKey.currentState?.validate() ?? false) {
        final isSuccess = await ref
            .read(authNotifierProvider.notifier)
            .signup(
              email: emailController.text.trim(),
              password: passwordController.text,
            );
        if (isSuccess) {
          TextInput.finishAutofillContext();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      }
    }

    void navigateToLogin() {
      Navigator.of(context).pop();
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
          return PasswordValidator.validate(value);
        },
      );
    }

    Widget buildPasswordRequirement(String requirement) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 14),
            const SizedBox(width: 4),
            Text(requirement, style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
    }

    Widget buildPasswordRequirements() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'パスワード要件:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          ...PasswordValidator.getPasswordRequirements().map(
            buildPasswordRequirement,
          ),
        ],
      );
    }

    Widget buildConfirmPasswordToggleButton() {
      return IconButton(
        icon: Icon(
          obscureConfirmPassword.value
              ? Icons.visibility
              : Icons.visibility_off,
        ),
        onPressed: () {
          obscureConfirmPassword.value = !obscureConfirmPassword.value;
        },
      );
    }

    Widget buildConfirmPasswordField() {
      return TextFormField(
        key: const Key('confirm_password_field'),
        controller: confirmPasswordController,
        decoration: InputDecoration(
          labelText: 'パスワード確認',
          border: const OutlineInputBorder(),
          suffixIcon: buildConfirmPasswordToggleButton(),
        ),
        obscureText: obscureConfirmPassword.value,
        autofillHints: const [AutofillHints.password],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'パスワード確認を入力してください';
          }
          if (value != passwordController.text) {
            return 'パスワードが一致しません';
          }
          return null;
        },
      );
    }

    Widget buildSignupButton() {
      return ElevatedButton(
        key: const Key('signup_button'),
        onPressed: signup,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('登録', style: TextStyle(fontSize: 16)),
      );
    }

    Widget buildLoginLink() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('すでにアカウントをお持ちの方'),
          TextButton(
            key: const Key('login_link'),
            onPressed: navigateToLogin,
            child: const Text('ログイン'),
          ),
        ],
      );
    }

    Widget buildLoadingIndicator() {
      return const Center(child: CircularProgressIndicator());
    }

    Widget buildForm(AuthState authState) {
      return AutofillGroup(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
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
                  const SizedBox(height: 8),
                  buildPasswordRequirements(),
                  const SizedBox(height: 16),
                  buildConfirmPasswordField(),
                  const SizedBox(height: 24),
                  buildSignupButton(),
                  const SizedBox(height: 32),
                  buildLoginLink(),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: buildForm(authState),
      ),
    );
  }
}
