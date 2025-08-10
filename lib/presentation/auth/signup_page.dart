import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/auth_state.dart';
import '../../application/managers/auth_manager.dart';
import '../../application/utils/password_validator.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key, required this.authManager});

  final AuthManager authManager;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    widget.authManager.addListener(_authStateListener);
  }

  @override
  void dispose() {
    widget.authManager.removeListener(_authStateListener);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _authStateListener() {
    if (widget.authManager.state.isAuthenticated) {
      // 認証成功時は AuthGuard がメインコンテンツを表示するが、
      // SignupPage をナビゲーションスタックから削除する必要がある
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      await widget.authManager.signup(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // サインアップ成功時に自動入力データを保存
      if (widget.authManager.state.isAuthenticated) {
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
        child: ListenableBuilder(
          listenable: widget.authManager,
          builder: (context, child) {
            return AutofillGroup(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.authManager.state.status == AuthStatus.loading)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        if (widget.authManager.state.status == AuthStatus.error ||
                            widget.authManager.state.status == AuthStatus.success)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: widget.authManager.state.status == AuthStatus.success 
                                  ? Colors.green.shade100 
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.authManager.state.status == AuthStatus.success 
                                    ? Colors.green.shade300 
                                    : Colors.red.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  widget.authManager.state.status == AuthStatus.success 
                                      ? Icons.check_circle 
                                      : Icons.error, 
                                  color: widget.authManager.state.status == AuthStatus.success 
                                      ? Colors.green.shade700 
                                      : Colors.red.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.authManager.state.errorMessage ??
                                        'エラーが発生しました',
                                    style: TextStyle(
                                      color: widget.authManager.state.status == AuthStatus.success 
                                          ? Colors.green.shade700 
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: widget.authManager.state.status == AuthStatus.success 
                                        ? Colors.green.shade700 
                                        : Colors.red.shade700,
                                  ),
                                  onPressed: () {
                                    widget.authManager.clearError();
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
