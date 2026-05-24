import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/infrastructure/factories/android_widget_cache_storage_factory.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';

class Settings extends ConsumerWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMemberState = ref.watch(currentMemberNotifierProvider);

    return Container(
      key: const Key('settings'),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.settings, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '設定',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          Text('Androidウィジェット', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildAndroidWidgetGroupSetting(context, ref, currentMemberState),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ログアウト（テスト用）'),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidWidgetGroupSetting(
    BuildContext context,
    WidgetRef ref,
    CurrentMemberState currentMemberState,
  ) {
    if (currentMemberState.status == CurrentMemberStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final member = currentMemberState.member;
    if (currentMemberState.status == CurrentMemberStatus.error ||
        member == null) {
      return const Text('メンバー情報を取得できないため設定できません');
    }

    return FutureBuilder<List<GroupDto>>(
      future: ref.read(getGroupsWithMembersUsecaseProvider).execute(member),
      builder: (context, groupsSnapshot) {
        if (!groupsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = groupsSnapshot.data!;
        if (groups.isEmpty) {
          return const Text('所属グループがありません');
        }

        return FutureBuilder<String?>(
          future: ref
              .read(androidWidgetCacheStorageProvider)
              .getTargetGroupId(),
          builder: (context, targetGroupSnapshot) {
            final selectedGroupId = targetGroupSnapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...groups.map(
                  (group) => ListTile(
                    leading: Icon(
                      group.id == selectedGroupId
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(group.name),
                    onTap: () async {
                      await ref
                          .read(selectAndroidWidgetTargetGroupUsecaseProvider)
                          .execute(group.id);
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ウィジェット表示対象を保存しました')),
                      );
                    },
                  ),
                ),
                OutlinedButton(
                  onPressed: selectedGroupId == null
                      ? null
                      : () async {
                          await ref
                              .read(
                                clearAndroidWidgetTargetGroupUsecaseProvider,
                              )
                              .execute();
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ウィジェット表示対象を解除しました')),
                          );
                        },
                  child: const Text('表示対象を解除'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
