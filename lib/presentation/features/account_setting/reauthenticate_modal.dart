import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/account/reauthenticate_usecase.dart';
import 'package:memora/core/app_logger.dart';

class ReauthenticateModal extends ConsumerStatefulWidget {
  const ReauthenticateModal({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  ConsumerState<ReauthenticateModal> createState() =>
      _ReauthenticateModalState();
}

class _ReauthenticateModalState extends ConsumerState<ReauthenticateModal> {
  late final ReauthenticateUseCase _reauthenticateUseCase;

  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _reauthenticateUseCase = ref.read(reauthenticateUseCaseProvider);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _reauthenticateUseCase.execute(password: password);
      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onSuccess?.call();
      }
    } catch (e, stack) {
      logger.e(
        'ReauthenticateModal._authenticate: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _buildTitle(),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildTitle() {
    return const Text('パスワード再入力');
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescription(),
        const SizedBox(height: 16),
        _buildPasswordField(),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          _buildErrorMessage(),
        ],
      ],
    );
  }

  Widget _buildDescription() {
    return const Text('操作を続行するには、現在のパスワードを入力してください');
  }

  Widget _buildPasswordField() {
    return TextField(
      key: const Key('passwordField'),
      controller: _passwordController,
      decoration: const InputDecoration(
        labelText: 'パスワード',
        border: OutlineInputBorder(),
      ),
      obscureText: true,
      enabled: !_isLoading,
    );
  }

  Widget _buildErrorMessage() {
    return Text(
      _errorMessage!,
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontSize: 12,
      ),
    );
  }

  List<Widget> _buildActions() {
    return [_buildCancelButton(), _buildAuthenticateButton()];
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
      child: const Text('キャンセル'),
    );
  }

  Widget _buildAuthenticateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _authenticate,
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('認証'),
    );
  }
}
