import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/usecases/account/get_current_user_usecase.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/features/auth/invitation_code_input_dialog.dart';
import 'package:memora/presentation/features/auth/member_creation_selection_dialog.dart';
import 'login_page.dart';

class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.isAuthenticated) {
      return child;
    }

    if (authState.requiresMemberSelection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMemberCreationDialog(context, ref);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const LoginPage();
  }

  Future<void> _showMemberCreationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final getCurrentUserUseCase = ref.read(getCurrentUserUseCaseProvider);
    final currentUser = await getCurrentUserUseCase.execute();

    if (currentUser == null) {
      await authNotifier.logout();
      return;
    }

    while (true) {
      if (!context.mounted) return;

      final selectedOption = await MemberCreationSelectionDialog.show(context);

      if (selectedOption == null) {
        await authNotifier.logout();
        return;
      }

      switch (selectedOption) {
        case MemberCreationOption.createNew:
          await authNotifier.createNewMember(currentUser);
          return;
        case MemberCreationOption.useInvitationCode:
          if (!context.mounted) return;
          final success = await _handleInvitationCodeInput(
            context,
            ref,
            currentUser,
          );
          if (success) {
            return;
          }
        case MemberCreationOption.backToLogin:
          await authNotifier.logout();
          return;
      }
    }
  }

  Future<bool> _handleInvitationCodeInput(
    BuildContext context,
    WidgetRef ref,
    UserDto currentUser,
  ) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);

    String? errorMessage;

    while (true) {
      if (!context.mounted) return true;

      final invitationCode = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            InvitationCodeInputDialog(errorMessage: errorMessage),
      );

      if (invitationCode == null) {
        return false;
      }

      final success = await authNotifier.acceptInvitation(
        invitationCode,
        userId: currentUser.id,
      );

      if (!success) {
        errorMessage = '招待コードが無効です。';
        continue;
      }
      return true;
    }
  }
}
