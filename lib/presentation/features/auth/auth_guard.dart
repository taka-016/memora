import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/value_objects/auth_state.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/shared/dialogs/invitation_code_input_modal.dart';
import 'package:memora/presentation/shared/dialogs/member_creation_selection_dialog.dart';
import 'login_page.dart';

class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    switch (authState.status) {
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return child;
      case AuthStatus.unauthenticated:
        if (authState.message == 'member_selection_required') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showMemberCreationDialog(context, ref);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const LoginPage();
    }
  }

  Future<void> _showMemberCreationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);

    final authService = ref.read(authServiceProvider);
    final currentUser = await authService.getCurrentUser();

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
    currentUser,
  ) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);

    String? errorMessage;

    while (true) {
      if (!context.mounted) return true;

      final invitationCode = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            InvitationCodeInputModal(errorMessage: errorMessage),
      );

      if (invitationCode == null) {
        return false;
      }

      final success = await authNotifier.acceptInvitation(
        invitationCode,
        currentUser,
      );

      if (!success) {
        errorMessage = '招待コードが無効です。';
        continue;
      }
      return true;
    }
  }
}
