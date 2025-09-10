import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/value_objects/auth_state.dart';
import '../../notifiers/auth_notifier.dart';
import '../../../application/utils/password_validator.dart';

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
      final isSuccess = await ref
          .read(authNotifierProvider.notifier)
          .signup(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (isSuccess) {
        TextInput.finishAutofillContext();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  AppBar _buildAppBar() {
    return AppBar(title: const Text('新規登録'));
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authNotifierProvider);
          return _buildForm(authState, ref);
        },
      ),
    );
  }

  Widget _buildForm(AuthState authState, WidgetRef ref) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
      const SizedBox(height: 8),
      _buildPasswordRequirements(),
      const SizedBox(height: 16),
      _buildConfirmPasswordField(),
      const SizedBox(height: 24),
      _buildSignupButton(),
      const SizedBox(height: 32),
      _buildLoginLink(),
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
              ref.read(authNotifierProvider.notifier).clearError();
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
        return PasswordValidator.validate(value);
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

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'パスワード要件:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        ...PasswordValidator.getPasswordRequirements().map(
          _buildPasswordRequirement,
        ),
      ],
    );
  }

  Widget _buildPasswordRequirement(String requirement) {
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

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      key: const Key('confirm_password_field'),
      controller: _confirmPasswordController,
      decoration: InputDecoration(
        labelText: 'パスワード確認',
        border: const OutlineInputBorder(),
        suffixIcon: _buildConfirmPasswordToggleButton(),
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
    );
  }

  Widget _buildConfirmPasswordToggleButton() {
    return IconButton(
      icon: Icon(
        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
      ),
      onPressed: () {
        setState(() {
          _obscureConfirmPassword = !_obscureConfirmPassword;
        });
      },
    );
  }

  Widget _buildSignupButton() {
    return ElevatedButton(
      key: const Key('signup_button'),
      onPressed: _signup,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('登録', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('すでにアカウントをお持ちの方'),
        TextButton(
          key: const Key('login_link'),
          onPressed: _navigateToLogin,
          child: const Text('ログイン'),
        ),
      ],
    );
  }
}
