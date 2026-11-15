import 'package:memora/presentation/notifiers/app_availability/app_availability_notifier.dart';
import 'package:memora/composition_root/providers/account_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';
import 'package:memora/presentation/features/auth/invitation_code_input_dialog.dart';
import 'package:memora/presentation/features/auth/member_creation_selection_dialog.dart';

import 'login_page.dart';
import 'auth_initialization_view.dart';

class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.isLoading || authState.hasInitializationError) {
      return const Scaffold(body: AuthInitializationView());
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
    if (!context.mounted) return true;
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => InvitationCodeInputDialog(
        onSubmit: (invitationCode) async {
          final accepted = await ref
              .read(authNotifierProvider.notifier)
              .acceptInvitation(invitationCode, userId: currentUser.id);
          if (accepted) return null;
          if (!ref.read(appAvailabilityNotifierProvider).canUseApp) {
            return '利用状況を確認できないため承諾できません。再確認してから再試行してください。';
          }
          return '招待コードが無効です。';
        },
      ),
    );
    return success ?? false;
  }
}
