import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/android_widget/update_android_widget_interval_usecase.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/infrastructure/factories/android_widget_cache_storage_factory.dart';
import 'package:memora/infrastructure/factories/android_widget_update_interval_storage_factory.dart';
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
  late final Future<AndroidWidgetUpdateInterval> _updateIntervalFuture;
  AndroidWidgetUpdateInterval? _selectedUpdateInterval;

  @override
  void initState() {
    super.initState();
    _updateIntervalFuture = ref
        .read(androidWidgetUpdateIntervalStorageProvider)
        .load();
  }

  @override
  Widget build(BuildContext context) {
    final currentMemberState = ref.watch(currentMemberNotifierProvider);

    return Scaffold(
      key: const Key('settings'),
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Androidウィジェット', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildAndroidWidgetGroupSetting(context, currentMemberState),
          const SizedBox(height: 16),
          _buildAndroidWidgetUpdateIntervalSetting(context),
        ],
      ),
    );
  }

  Widget _buildAndroidWidgetUpdateIntervalSetting(BuildContext context) {
    return FutureBuilder<AndroidWidgetUpdateInterval>(
      future: _updateIntervalFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final selectedInterval = _selectedUpdateInterval ?? snapshot.data!;
        return DropdownButtonFormField<AndroidWidgetUpdateInterval>(
          key: ValueKey(selectedInterval),
          initialValue: selectedInterval,
          decoration: const InputDecoration(
            labelText: '更新間隔',
            border: OutlineInputBorder(),
          ),
          items: AndroidWidgetUpdateInterval.values
              .map(
                (interval) => DropdownMenuItem<AndroidWidgetUpdateInterval>(
                  value: interval,
                  child: Text(interval.label),
                ),
              )
              .toList(),
          onChanged: (interval) async {
            if (interval == null || interval == selectedInterval) {
              return;
            }
            await ref
                .read(updateAndroidWidgetIntervalUsecaseProvider)
                .execute(interval);
            if (!context.mounted) {
              return;
            }
            setState(() {
              _selectedUpdateInterval = interval;
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('ウィジェット更新間隔を保存しました')));
          },
        );
      },
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
            return DropdownButtonFormField<String>(
              initialValue: selectedGroupId,
              decoration: const InputDecoration(
                labelText: '表示対象グループ',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('未選択')),
                ...groups.map(
                  (group) => DropdownMenuItem<String>(
                    value: group.id,
                    child: Text(group.name),
                  ),
                ),
              ],
              onChanged: (groupId) async {
                if (groupId == selectedGroupId) {
                  return;
                }
                if (groupId == null) {
                  await ref
                      .read(clearAndroidWidgetTargetGroupUsecaseProvider)
                      .execute();
                  _updateSelectedAndroidWidgetGroupId(null);
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ウィジェット表示対象を解除しました')),
                  );
                  return;
                }

                await ref
                    .read(selectAndroidWidgetTargetGroupUsecaseProvider)
                    .execute(groupId);
                _updateSelectedAndroidWidgetGroupId(groupId);
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ウィジェット表示対象を保存しました')),
                );
              },
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
            _updateSelectedAndroidWidgetGroupId(groupId);
          }
          return groupId;
        });
  }

  void _updateSelectedAndroidWidgetGroupId(String? groupId) {
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedAndroidWidgetGroupId = groupId;
      _isTargetGroupIdLoaded = true;
    });
  }
}
