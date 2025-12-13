import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/member/create_member_usecase.dart';
import 'package:memora/application/usecases/member/create_or_update_member_invitation_usecase.dart';
import 'package:memora/application/usecases/member/delete_member_usecase.dart';
import 'package:memora/application/usecases/member/get_managed_members_usecase.dart';
import 'package:memora/application/usecases/member/get_member_by_id_usecase.dart';
import 'package:memora/application/usecases/member/update_member_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/member/member_edit_modal.dart';
import 'package:memora/presentation/shared/dialogs/delete_confirm_dialog.dart';
import 'package:share_plus/share_plus.dart';

class MemberManagement extends HookConsumerWidget {
  final MemberDto member;

  const MemberManagement({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getManagedMembersUsecase = ref.read(getManagedMembersUsecaseProvider);
    final createMemberUsecase = ref.read(createMemberUsecaseProvider);
    final updateMemberUsecase = ref.read(updateMemberUsecaseProvider);
    final deleteMemberUsecase = ref.read(deleteMemberUsecaseProvider);
    final getMemberByIdUseCase = ref.read(getMemberByIdUsecaseProvider);
    final createOrUpdateMemberInvitationUsecase = ref.read(
      createOrUpdateMemberInvitationUsecaseProvider,
    );

    final managedMembers = useState<List<MemberDto>>([]);
    final isLoading = useState(true);

    Future<void> loadData() async {
      isLoading.value = true;

      try {
        final managedMembersResult = await getManagedMembersUsecase.execute(
          member,
        );
        final currentMember = await getMemberByIdUseCase.execute(member.id);
        if (currentMember == null) {
          throw Exception('ログインユーザーメンバーの最新情報の取得に失敗しました');
        }
        managedMembers.value = List<MemberDto>.from([
          currentMember,
          ...managedMembersResult,
        ]);
      } catch (e, stack) {
        logger.e(
          'MemberManagement.loadData: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('データの読み込みに失敗しました: $e')));
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    useEffect(() {
      loadData();
      return null;
    }, const []);

    Future<void> handleMemberInvite(MemberDto targetMember) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        final invitationCode = await createOrUpdateMemberInvitationUsecase
            .execute(inviteeId: targetMember.id, inviterId: member.id);

        if (!context.mounted) {
          return;
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
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    await Share.share(
                      'あなたのMemoraへの招待コード\n\n$invitationCode\n\nこのコードをアプリで入力してください。',
                      subject: 'Memoraへの招待',
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
      } catch (e, stack) {
        logger.e(
          'MemberManagement.handleMemberInvite: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('招待コードの生成に失敗しました: $e')),
          );
        }
      }
    }

    Future<void> deleteMember(MemberDto targetMember) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        await deleteMemberUsecase.execute(targetMember.id);
        if (!context.mounted) {
          return;
        }
        await loadData();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('メンバーを削除しました')),
        );
      } catch (e, stack) {
        logger.e(
          'MemberManagement.deleteMember: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('削除に失敗しました: $e')),
          );
        }
      }
    }

    Future<void> showDeleteConfirmDialog(MemberDto targetMember) async {
      await DeleteConfirmDialog.show(
        context,
        title: 'メンバー削除',
        content: '${targetMember.displayName}を削除しますか？',
        onConfirm: () => deleteMember(targetMember),
      );
    }

    Future<void> showAddMemberDialog() async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (dialogContext) => MemberEditModal(
          onSave: (newMember) async {
            try {
              await createMemberUsecase.execute(newMember, member.id);
              if (!dialogContext.mounted) {
                return;
              }
              await loadData();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('メンバーを作成しました')),
              );
            } catch (e, stack) {
              logger.e(
                'MemberManagement.showAddMemberDialog: ${e.toString()}',
                error: e,
                stackTrace: stack,
              );
              if (dialogContext.mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('作成に失敗しました: $e')),
                );
              }
            }
          },
        ),
      );
    }

    Future<void> showEditMemberDialog(MemberDto targetMember) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (dialogContext) => MemberEditModal(
          member: targetMember,
          onSave: (updatedMember) async {
            try {
              await updateMemberUsecase.execute(updatedMember);
              if (!dialogContext.mounted) {
                return;
              }
              await loadData();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('メンバーを更新しました')),
              );
            } catch (e, stack) {
              logger.e(
                'MemberManagement.showEditMemberDialog: ${e.toString()}',
                error: e,
                stackTrace: stack,
              );
              if (dialogContext.mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('更新に失敗しました: $e')),
                );
              }
            }
          },
          onInvite: targetMember.id != member.id
              ? (memberDto) async {
                  await handleMemberInvite(memberDto);
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
              onPressed: showAddMemberDialog,
              icon: const Icon(Icons.add),
              label: const Text('メンバー追加'),
            ),
          ],
        ),
      );
    }

    Widget buildMemberList() {
      return Expanded(
        child: RefreshIndicator(
          onRefresh: loadData,
          child: ListView.builder(
            itemCount: managedMembers.value.length,
            itemBuilder: (context, index) {
              final targetMember = managedMembers.value[index];
              final isCurrentUser = index == 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(targetMember.displayName.substring(0, 1)),
                  ),
                  title: Text(targetMember.displayName),
                  subtitle:
                      (targetMember.email != null ||
                          targetMember.phoneNumber != null)
                      ? Text(
                          targetMember.email ?? targetMember.phoneNumber ?? '',
                        )
                      : null,
                  onTap: () => showEditMemberDialog(targetMember),
                  trailing: (!isCurrentUser && targetMember.accountId == null)
                      ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              showDeleteConfirmDialog(targetMember),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      key: const Key('member_settings'),
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [buildHeader(), const Divider(), buildMemberList()],
            ),
    );
  }
}
