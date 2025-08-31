import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/value_objects/auth_state.dart';
import '../../../application/managers/auth_manager.dart';
import 'signup_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordlessEmailController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordlessEmailController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(authManagerProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      final authState = ref.read(authManagerProvider);
      if (authState.isAuthenticated) {
        TextInput.finishAutofillContext();
      }
    }
  }

  void _navigateToSignup() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SignupPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  AppBar _buildAppBar() {
    return AppBar(title: const Text('ログイン'));
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authManagerProvider);
          return _buildForm(authState, ref);
        },
      ),
    );
  }

  Widget _buildForm(AuthState authState, WidgetRef ref) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (authState.status == AuthStatus.loading)
              _buildLoadingIndicator()
            else
              ..._buildFormContent(authState, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  List<Widget> _buildFormContent(AuthState authState, WidgetRef ref) {
    return [
      if (authState.message.isNotEmpty) _buildMessageContainer(authState, ref),
      _buildEmailField(),
      const SizedBox(height: 16),
      _buildPasswordField(),
      const SizedBox(height: 24),
      _buildLoginButton(),
      const SizedBox(height: 32),
      _buildSignupLink(),
    ];
  }

  Widget _buildMessageContainer(AuthState authState, WidgetRef ref) {
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
              ref.read(authManagerProvider.notifier).clearError();
            },
            tooltip: 'エラーを閉じる',
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
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
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return '正しいメールアドレスを入力してください';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      key: const Key('password_field'),
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'パスワード',
        border: const OutlineInputBorder(),
        suffixIcon: _buildPasswordToggleButton(),
      ),
      obscureText: _obscurePassword,
      autofillHints: const [AutofillHints.password],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'パスワードを入力してください';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordToggleButton() {
    return IconButton(
      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
      onPressed: () {
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      key: const Key('login_button'),
      onPressed: _login,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('ログイン', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('アカウントをお持ちでない方'),
        TextButton(
          key: const Key('signup_link'),
          onPressed: _navigateToSignup,
          child: const Text('新規登録'),
        ),
      ],
    );
  }
}
