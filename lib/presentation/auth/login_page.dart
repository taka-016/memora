import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/auth_state.dart';
import '../../application/managers/auth_manager.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authManager});

  final AuthManager authManager;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordlessEmailController = TextEditingController();
  bool _obscurePassword = true;

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
    _passwordlessEmailController.dispose();
    super.dispose();
  }

  void _authStateListener() {
    if (widget.authManager.state.isAuthenticated) {
      // 認証成功時は AuthGuard がメインコンテンツを表示するが、
      // LoginPage をナビゲーションスタックから削除する必要がある
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      await widget.authManager.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // ログイン成功時に自動入力データを保存
      if (widget.authManager.state.isAuthenticated) {
        TextInput.finishAutofillContext();
      }
    }
  }

  void _navigateToSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SignupPage(authManager: widget.authManager),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListenableBuilder(
          listenable: widget.authManager,
          builder: (context, child) {
            return AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.authManager.state.status == AuthStatus.loading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      if (widget.authManager.state.message != null &&
                          widget.authManager.state.message!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color:
                                widget.authManager.state.messageType ==
                                    MessageType.info
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  widget.authManager.state.messageType ==
                                      MessageType.info
                                  ? Colors.green.shade300
                                  : Colors.red.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.authManager.state.messageType ==
                                        MessageType.info
                                    ? Icons.check_circle
                                    : Icons.error,
                                color:
                                    widget.authManager.state.messageType ==
                                        MessageType.info
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.authManager.state.message ??
                                      'エラーが発生しました',
                                  style: TextStyle(
                                    color:
                                        widget.authManager.state.messageType ==
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
                                      widget.authManager.state.messageType ==
                                          MessageType.info
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
                          if (value == null || value.isEmpty) {
                            return 'パスワードを入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        key: const Key('login_button'),
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'ログイン',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('アカウントをお持ちでない方'),
                          TextButton(
                            key: const Key('signup_link'),
                            onPressed: _navigateToSignup,
                            child: const Text('新規登録'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
