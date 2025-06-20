import 'package:flutter/material.dart';
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
      await widget.authManager.login(email: _emailController.text.trim(), password: _passwordController.text);
    }
  }

  void _navigateToSignup() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignupPage(authManager: widget.authManager)));
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
            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.authManager.state.status == AuthStatus.loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    if (widget.authManager.state.status == AuthStatus.error)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.authManager.state.errorMessage ?? 'エラーが発生しました',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red.shade700),
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
                      decoration: const InputDecoration(labelText: 'メールアドレス', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'メールアドレスを入力してください';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return '正しいメールアドレスを入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('password_field'),
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'パスワード', border: OutlineInputBorder()),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'パスワードを入力してください';
                        }
                        if (value.length < 6) {
                          return 'パスワードは6文字以上で入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      key: const Key('login_button'),
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('ログイン', style: TextStyle(fontSize: 16)),
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
            );
          },
        ),
      ),
    );
  }
}
