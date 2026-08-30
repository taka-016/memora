import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/android_widget/update_android_widget_interval_usecase.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';

final androidWidgetUpdateIntervalProvider =
    AsyncNotifierProvider.autoDispose<
      AndroidWidgetUpdateIntervalNotifier,
      AndroidWidgetUpdateIntervalState
    >(AndroidWidgetUpdateIntervalNotifier.new, retry: (_, _) => null);

class AndroidWidgetUpdateIntervalState extends Equatable {
  const AndroidWidgetUpdateIntervalState({
    required this.interval,
    this.isSaving = false,
    this.operationRevision = 0,
  });

  final AndroidWidgetUpdateInterval interval;
  final bool isSaving;
  final int operationRevision;

  @override
  List<Object?> get props => [interval, isSaving, operationRevision];
}

class AndroidWidgetUpdateIntervalNotifier
    extends AsyncNotifier<AndroidWidgetUpdateIntervalState> {
  @override
  Future<AndroidWidgetUpdateIntervalState> build() async {
    final interval = await ref
        .read(androidWidgetUpdateIntervalStorageProvider)
        .load();
    return AndroidWidgetUpdateIntervalState(interval: interval);
  }

  Future<bool> save(AndroidWidgetUpdateInterval interval) async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isSaving ||
        currentState.interval == interval) {
      return false;
    }

    final keepAliveLink = ref.keepAlive();
    final operationRevision = currentState.operationRevision + 1;
    state = AsyncData(
      AndroidWidgetUpdateIntervalState(
        interval: currentState.interval,
        isSaving: true,
        operationRevision: operationRevision,
      ),
    );
    try {
      await ref
          .read(updateAndroidWidgetIntervalUsecaseProvider)
          .execute(interval);
      if (!ref.mounted) {
        return false;
      }
      state = AsyncData(
        AndroidWidgetUpdateIntervalState(
          interval: interval,
          operationRevision: operationRevision,
        ),
      );
      return true;
    } catch (_) {
      if (ref.mounted) {
        state = AsyncData(
          AndroidWidgetUpdateIntervalState(
            interval: currentState.interval,
            operationRevision: operationRevision,
          ),
        );
      }
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }
}

class AndroidWidgetTargetGroupState extends Equatable {
  const AndroidWidgetTargetGroupState({
    required this.groups,
    required this.selectedGroupId,
    required this.persistedGroupId,
    this.isSaving = false,
    this.operationRevision = 0,
  });

  final List<GroupDto> groups;
  final String? selectedGroupId;
  final String? persistedGroupId;
  final bool isSaving;
  final int operationRevision;

  @override
  List<Object?> get props => [
    groups,
    selectedGroupId,
    persistedGroupId,
    isSaving,
    operationRevision,
  ];
}

final androidWidgetTargetGroupProvider = AsyncNotifierProvider.autoDispose
    .family<
      AndroidWidgetTargetGroupNotifier,
      AndroidWidgetTargetGroupState,
      MemberDto
    >(AndroidWidgetTargetGroupNotifier.new, retry: (_, _) => null);

class AndroidWidgetTargetGroupNotifier
    extends AsyncNotifier<AndroidWidgetTargetGroupState> {
  AndroidWidgetTargetGroupNotifier(this._member);

  final MemberDto _member;

  @override
  Future<AndroidWidgetTargetGroupState> build() async {
    final groupsFuture = ref
        .read(getGroupsWithMembersUsecaseProvider)
        .execute(_member);
    final persistedGroupIdFuture = ref
        .read(androidWidgetCacheStorageProvider)
        .getTargetGroupId();
    final loadResults = await Future.wait<Object?>([
      groupsFuture,
      persistedGroupIdFuture,
    ], eagerError: true);
    final groups = loadResults[0]! as List<GroupDto>;
    final persistedGroupId = loadResults[1] as String?;

    return AndroidWidgetTargetGroupState(
      groups: groups,
      selectedGroupId: groups.any((group) => group.id == persistedGroupId)
          ? persistedGroupId
          : null,
      persistedGroupId: persistedGroupId,
    );
  }

  Future<bool> select(String? groupId) async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isSaving ||
        currentState.persistedGroupId == groupId) {
      return false;
    }

    final keepAliveLink = ref.keepAlive();
    final operationRevision = currentState.operationRevision + 1;
    state = AsyncData(
      AndroidWidgetTargetGroupState(
        groups: currentState.groups,
        selectedGroupId: currentState.selectedGroupId,
        persistedGroupId: currentState.persistedGroupId,
        isSaving: true,
        operationRevision: operationRevision,
      ),
    );
    try {
      await _saveSelection(groupId);
      if (!ref.mounted) {
        return false;
      }
      state = AsyncData(
        AndroidWidgetTargetGroupState(
          groups: currentState.groups,
          selectedGroupId: groupId,
          persistedGroupId: groupId,
          operationRevision: operationRevision,
        ),
      );
      return true;
    } catch (_) {
      if (ref.mounted) {
        state = AsyncData(
          AndroidWidgetTargetGroupState(
            groups: currentState.groups,
            selectedGroupId: currentState.selectedGroupId,
            persistedGroupId: currentState.persistedGroupId,
            operationRevision: operationRevision,
          ),
        );
      }
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<void> _saveSelection(String? groupId) {
    if (groupId == null) {
      return ref.read(clearAndroidWidgetTargetGroupUsecaseProvider).execute();
    }
    return ref
        .read(selectAndroidWidgetTargetGroupUsecaseProvider)
        .execute(groupId);
  }
}

class Settings extends ConsumerWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMemberState = ref.watch(currentMemberNotifierProvider);

    return Scaffold(
      key: const Key('settings'),
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Androidウィジェット', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildAndroidWidgetGroupSetting(context, ref, currentMemberState),
          const SizedBox(height: 16),
          _buildAndroidWidgetUpdateIntervalSetting(context, ref),
        ],
      ),
    );
  }

  Widget _buildAndroidWidgetUpdateIntervalSetting(
    BuildContext context,
    WidgetRef ref,
  ) {
    final intervalState = ref.watch(androidWidgetUpdateIntervalProvider);
    final setting = intervalState.value;
    if (setting == null) {
      return _buildLoadingOrRetry(
        hasError: intervalState.hasError,
        errorMessage: 'ウィジェット更新間隔を取得できませんでした',
        onRetry: () => ref.invalidate(androidWidgetUpdateIntervalProvider),
      );
    }

    return DropdownButtonFormField<AndroidWidgetUpdateInterval>(
      key: ValueKey((setting.interval, setting.operationRevision)),
      initialValue: setting.interval,
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
      onChanged: setting.isSaving
          ? null
          : (interval) async {
              if (interval == null) {
                return;
              }
              try {
                final saved = await ref
                    .read(androidWidgetUpdateIntervalProvider.notifier)
                    .save(interval);
                if (!saved || !context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ウィジェット更新間隔を保存しました')),
                );
              } catch (_) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ウィジェット更新間隔を保存できませんでした')),
                );
              }
            },
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

    final provider = androidWidgetTargetGroupProvider(member);
    final targetGroupState = ref.watch(provider);
    final setting = targetGroupState.value;
    if (setting == null) {
      return _buildLoadingOrRetry(
        hasError: targetGroupState.hasError,
        errorMessage: 'ウィジェット表示対象を取得できませんでした',
        onRetry: () => ref.invalidate(provider),
      );
    }
    if (setting.groups.isEmpty) {
      if (setting.persistedGroupId != null) {
        return Row(
          children: [
            const Expanded(child: Text('所属グループがありません')),
            TextButton(
              onPressed: setting.isSaving
                  ? null
                  : () => _saveTargetGroupSelection(
                      context,
                      ref.read(provider.notifier),
                      null,
                    ),
              child: const Text('表示対象を解除'),
            ),
          ],
        );
      }
      return const Text('所属グループがありません');
    }

    return DropdownButtonFormField<String>(
      key: ValueKey((
        member.id,
        setting.selectedGroupId,
        setting.operationRevision,
      )),
      initialValue: setting.selectedGroupId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: '表示対象グループ',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('未選択')),
        ...setting.groups.map(
          (group) => DropdownMenuItem<String>(
            value: group.id,
            child: Text(
              group.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: setting.isSaving
          ? null
          : (groupId) => _saveTargetGroupSelection(
              context,
              ref.read(provider.notifier),
              groupId,
            ),
    );
  }

  Future<void> _saveTargetGroupSelection(
    BuildContext context,
    AndroidWidgetTargetGroupNotifier notifier,
    String? groupId,
  ) async {
    try {
      final saved = await notifier.select(groupId);
      if (!saved || !context.mounted) {
        return;
      }
      final message = groupId == null
          ? 'ウィジェット表示対象を解除しました'
          : 'ウィジェット表示対象を保存しました';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ウィジェット表示対象を保存できませんでした')));
    }
  }

  Widget _buildLoadingOrRetry({
    required bool hasError,
    required String errorMessage,
    required VoidCallback onRetry,
  }) {
    if (hasError) {
      return Row(
        children: [
          Expanded(child: Text(errorMessage)),
          TextButton(onPressed: onRetry, child: const Text('再試行')),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}
