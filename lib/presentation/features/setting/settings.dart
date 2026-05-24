import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/infrastructure/factories/android_widget_cache_storage_factory.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  ConsumerState<Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  String? _loadedMemberId;
  Future<List<GroupDto>>? _groupsFuture;
  Future<String?>? _targetGroupIdFuture;
  String? _selectedAndroidWidgetGroupId;
  bool _isTargetGroupIdLoaded = false;

  @override
  Widget build(BuildContext context) {
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
          _buildAndroidWidgetGroupSetting(context, currentMemberState),
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

    _loadAndroidWidgetSetting(member);
    return FutureBuilder<List<GroupDto>>(
      future: _groupsFuture,
      builder: (context, groupsSnapshot) {
        if (!groupsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = groupsSnapshot.data!;
        if (groups.isEmpty) {
          return const Text('所属グループがありません');
        }

        return FutureBuilder<String?>(
          future: _targetGroupIdFuture,
          builder: (context, targetGroupSnapshot) {
            if (!_isTargetGroupIdLoaded && !targetGroupSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final selectedGroupId = _selectedAndroidWidgetGroupId;
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
                      if (mounted) {
                        setState(() {
                          _selectedAndroidWidgetGroupId = group.id;
                          _isTargetGroupIdLoaded = true;
                        });
                      }
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
                          if (mounted) {
                            setState(() {
                              _selectedAndroidWidgetGroupId = null;
                              _isTargetGroupIdLoaded = true;
                            });
                          }
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

  void _loadAndroidWidgetSetting(MemberDto member) {
    if (_loadedMemberId == member.id) {
      return;
    }

    _loadedMemberId = member.id;
    _isTargetGroupIdLoaded = false;
    _selectedAndroidWidgetGroupId = null;
    _groupsFuture = ref
        .read(getGroupsWithMembersUsecaseProvider)
        .execute(member);
    _targetGroupIdFuture = ref
        .read(androidWidgetCacheStorageProvider)
        .getTargetGroupId()
        .then((groupId) {
          if (mounted && _loadedMemberId == member.id) {
            setState(() {
              _selectedAndroidWidgetGroupId = groupId;
              _isTargetGroupIdLoaded = true;
            });
          }
          return groupId;
        });
  }
}
