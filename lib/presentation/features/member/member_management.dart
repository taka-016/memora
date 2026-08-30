import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/member/create_or_update_member_invitation_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/member/member_edit_modal.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/member/member_management_notifier.dart';
import 'package:memora/presentation/shared/dialogs/delete_confirm_dialog.dart';
import 'package:share_plus/share_plus.dart';

class MemberManagement extends HookConsumerWidget {
  const MemberManagement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMember = ref.watch(currentMemberNotifierProvider).member;
    if (currentMember == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final managementProvider = memberManagementNotifierProvider(currentMember);
    final state = ref.watch(memberManagementNotifierProvider(currentMember));
    final managementNotifier = ref.read(managementProvider.notifier);
    final invite = ref.read(createOrUpdateMemberInvitationUsecaseProvider);
    final isMemberOperationInProgressRef = useRef(false);

    void showSnackBar(String message) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    ref.listen<AsyncValue<MemberManagementState>>(managementProvider, (
      previous,
      next,
    ) {
      final loadFailed =
          next.hasError &&
          (!(previous?.hasError ?? false) || previous?.error != next.error);
      if (loadFailed) {
        final error = next.error;
        final displayedError = error is StateError
            ? 'Exception: ${error.message}'
            : error.toString();
        showSnackBar('データの読み込みに失敗しました: $displayedError');
      }
    });

    Future<T> runExclusiveMemberOperation<T>({
      required T blockedResult,
      required Future<T> Function() execute,
    }) async {
      if (isMemberOperationInProgressRef.value) {
        return blockedResult;
      }
      isMemberOperationInProgressRef.value = true;
      try {
        return await execute();
      } finally {
        isMemberOperationInProgressRef.value = false;
      }
    }

    Future<void> refreshMembers() async {
      await runExclusiveMemberOperation(
        blockedResult: false,
        execute: () async {
          try {
            final refreshStarted = await managementNotifier.refreshMembers();
            if (!refreshStarted) {
              return false;
            }
            await ref.read(managementProvider.future);
          } catch (_) {
            // 失敗表示はProviderのAsyncErrorを監視するref.listenで行う。
          }
          return true;
        },
      );
    }

    Future<void> runMutationWithFeedback({
      required Future<bool> Function() execute,
      required String successMessage,
      required String failureMessage,
    }) async {
      await runExclusiveMemberOperation(
        blockedResult: false,
        execute: () async {
          try {
            final succeeded = await execute();
            if (!context.mounted || !succeeded) {
              return false;
            }
            showSnackBar(successMessage);
            return true;
          } catch (e) {
            if (context.mounted) {
              showSnackBar('$failureMessage: $e');
            }
            return false;
          }
        },
      );
    }

    Future<void> handleMemberInvite(
      MemberDto targetMember,
      BuildContext editDialogContext,
    ) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      await runExclusiveMemberOperation(
        blockedResult: false,
        execute: () async {
          try {
            final invitationCode = await invite.execute(
              inviteeId: targetMember.id,
              inviterId: currentMember.id,
            );

            if (!context.mounted || !editDialogContext.mounted) {
              return false;
            }

            await showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('招待コード'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${targetMember.displayName}さんの招待コードが生成されました。'),
                    const SizedBox(height: 16),
                    SelectableText(
                      invitationCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      try {
                        await SharePlus.instance.share(
                          ShareParams(
                            text:
                                'あなたのMemoraへの招待コード\n\n$invitationCode\n\nこのコードをアプリで入力してください。',
                            subject: 'Memoraへの招待',
                          ),
                        );
                      } catch (e, stack) {
                        logger.e(
                          'MemberManagement.handleMemberInvite.share: ${e.toString()}',
                          error: e,
                          stackTrace: stack,
                        );
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('共有に失敗しました')),
                        );
                      }
                    },
                    child: const Text('共有'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('閉じる'),
                  ),
                ],
              ),
            );
            return true;
          } catch (e, stack) {
            logger.e(
              'MemberManagement.handleMemberInvite: ${e.toString()}',
              error: e,
              stackTrace: stack,
            );
            if (context.mounted && editDialogContext.mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('招待コードの生成に失敗しました: $e')),
              );
            }
            return false;
          }
        },
      );
    }

    Future<void> showDeleteConfirmDialog(MemberDto targetMember) async {
      if (isMemberOperationInProgressRef.value) {
        return;
      }
      await DeleteConfirmDialog.show(
        context,
        title: 'メンバー削除',
        content: '${targetMember.displayName}を削除しますか？',
        onConfirm: () => runMutationWithFeedback(
          execute: () => managementNotifier.deleteMember(targetMember.id),
          successMessage: 'メンバーを削除しました',
          failureMessage: '削除に失敗しました',
        ),
      );
    }

    Future<void> showAddMemberDialog() async {
      if (isMemberOperationInProgressRef.value) {
        return;
      }
      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => MemberEditModal(
          onSave: (newMember) => runMutationWithFeedback(
            execute: () => managementNotifier.createMember(newMember),
            successMessage: 'メンバーを作成しました',
            failureMessage: '作成に失敗しました',
          ),
        ),
      );
    }

    Future<void> showEditMemberDialog(MemberDto targetMember) async {
      if (isMemberOperationInProgressRef.value) {
        return;
      }
      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (dialogContext) => MemberEditModal(
          member: targetMember,
          onSave: (updatedMember) => runMutationWithFeedback(
            execute: () => managementNotifier.updateMember(updatedMember),
            successMessage: 'メンバーを更新しました',
            failureMessage: '更新に失敗しました',
          ),
          onInvite: targetMember.id != currentMember.id
              ? (memberDto) async {
                  await handleMemberInvite(memberDto, dialogContext);
                }
              : null,
        ),
      );
    }

    Widget buildHeader() {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Text(
              'メンバー管理',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: state.hasValue ? showAddMemberDialog : null,
              icon: const Icon(Icons.add),
              label: const Text('メンバー追加'),
            ),
          ],
        ),
      );
    }

    Widget buildEmptyState() {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '管理しているメンバーがいません',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'メンバーを追加してください',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    Widget buildMemberListView() {
      return ListView.builder(
        itemCount: state.requireValue.members.length,
        itemBuilder: (context, index) {
          final targetMember = state.requireValue.members[index];
          final isCurrentUser = index == 0;
          final email = targetMember.email?.trim();
          final phoneNumber = targetMember.phoneNumber?.trim();
          String? subtitleText;
          if (email != null && email.isNotEmpty) {
            subtitleText = email;
          } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
            subtitleText = phoneNumber;
          }
          final subtitle = subtitleText != null ? Text(subtitleText) : null;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(targetMember.displayName.substring(0, 1)),
              ),
              title: Text(targetMember.displayName),
              subtitle: subtitle,
              onTap: () => showEditMemberDialog(targetMember),
              trailing: (!isCurrentUser && targetMember.accountId == null)
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => showDeleteConfirmDialog(targetMember),
                    )
                  : null,
            ),
          );
        },
      );
    }

    Widget buildMemberListContent() {
      if (state.requireValue.members.isEmpty) {
        return buildEmptyState();
      }
      return RefreshIndicator(
        onRefresh: refreshMembers,
        child: buildMemberListView(),
      );
    }

    Widget buildLoadingState() {
      return const Center(child: CircularProgressIndicator());
    }

    Widget buildBody() {
      if (!state.hasValue) {
        if (state.hasError) {
          return Column(
            children: [
              buildHeader(),
              const Divider(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('メンバー一覧を読み込めませんでした'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: refreshMembers,
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return buildLoadingState();
      }

      return Column(
        children: [
          buildHeader(),
          const Divider(),
          Expanded(child: buildMemberListContent()),
        ],
      );
    }

    return Container(key: const Key('member_settings'), child: buildBody());
  }
}
