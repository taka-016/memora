import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/core/validators/password_validator.dart';
import 'package:memora/core/app_logger.dart';

class PasswordChangeModal extends HookWidget {
  final Function(String) onPasswordChange;

  const PasswordChangeModal({super.key, required this.onPasswordChange});

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final isLoading = useState(false);
    final obscureNewPassword = useState(true);
    final obscureConfirmPassword = useState(true);

    Future<void> updatePassword() async {
      final currentState = formKey.currentState;
      if (currentState == null || !currentState.validate()) {
        return;
      }

      isLoading.value = true;

      try {
        await onPasswordChange(newPasswordController.text);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e, stack) {
        logger.e(
          'PasswordChangeModal._updatePassword: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Material(
        type: MaterialType.card,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'パスワード変更',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'パスワード要件:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...PasswordValidator.getPasswordRequirements().map(
                          (requirement) => Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              bottom: 4.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  requirement,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('newPasswordField'),
                      controller: newPasswordController,
                      obscureText: obscureNewPassword.value,
                      decoration: InputDecoration(
                        labelText: '新しいパスワード',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            obscureNewPassword.value =
                                !obscureNewPassword.value;
                          },
                        ),
                      ),
                      validator: (value) {
                        return PasswordValidator.validate(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('confirmPasswordField'),
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword.value,
                      decoration: InputDecoration(
                        labelText: 'パスワード確認',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            obscureConfirmPassword.value =
                                !obscureConfirmPassword.value;
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'パスワード確認を入力してください';
                        }
                        if (value != newPasswordController.text) {
                          return 'パスワードが一致しません';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isLoading.value
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isLoading.value ? null : updatePassword,
                    child: isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('更新'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
