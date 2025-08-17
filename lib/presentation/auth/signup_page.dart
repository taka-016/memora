import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/value-objects/auth_state.dart';
import '../../application/managers/auth_manager.dart';
import '../../application/utils/password_validator.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(authManagerProvider.notifier)
          .signup(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // サインアップ成功時に自動入力データを保存
      final authState = ref.read(authManagerProvider);
      if (authState.isAuthenticated) {
        TextInput.finishAutofillContext();
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authManagerProvider);
            return AutofillGroup(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (authState.status == AuthStatus.loading)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        if (authState.message.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: authState.messageType == MessageType.info
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: authState.messageType == MessageType.info
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  authState.messageType == MessageType.info
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color:
                                      authState.messageType == MessageType.info
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authState.message,
                                    style: TextStyle(
                                      color:
                                          authState.messageType ==
                                              MessageType.info
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color:
                                        authState.messageType ==
                                            MessageType.info
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(authManagerProvider.notifier)
                                        .clearError();
                                  },
                                  tooltip: 'エラーを閉じる',
                                ),
                              ],
                            ),
                          ),
                        TextFormField(
                          key: const Key('email_field'),
                          controller: _emailController,
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
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return '正しいメールアドレスを入力してください';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('password_field'),
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'パスワード',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          validator: (value) {
                            return PasswordValidator.validate(value);
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'パスワード要件:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...PasswordValidator.getPasswordRequirements().map(
                          (requirement) => Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              bottom: 2.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  requirement,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('confirm_password_field'),
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'パスワード確認',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureConfirmPassword,
                          autofillHints: const [AutofillHints.password],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'パスワード確認を入力してください';
                            }
                            if (value != _passwordController.text) {
                              return 'パスワードが一致しません';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          key: const Key('signup_button'),
                          onPressed: _signup,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            '登録',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('すでにアカウントをお持ちの方'),
                            TextButton(
                              key: const Key('login_link'),
                              onPressed: _navigateToLogin,
                              child: const Text('ログイン'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
