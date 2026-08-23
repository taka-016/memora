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
import 'package:memora/presentation/notifiers/current_member_notifier.dart';

final androidWidgetUpdateIntervalProvider =
    AsyncNotifierProvider.autoDispose<
      AndroidWidgetUpdateIntervalNotifier,
      AndroidWidgetUpdateInterval
    >(AndroidWidgetUpdateIntervalNotifier.new, retry: (_, _) => null);

class AndroidWidgetUpdateIntervalNotifier
    extends AsyncNotifier<AndroidWidgetUpdateInterval> {
  bool _isSaving = false;
  int _operationRevision = 0;

  int get operationRevision => _operationRevision;

  @override
  Future<AndroidWidgetUpdateInterval> build() {
    return ref.read(androidWidgetUpdateIntervalStorageProvider).load();
  }

  Future<bool> save(AndroidWidgetUpdateInterval interval) async {
    final currentInterval = state.value;
    if (_isSaving || currentInterval == null || currentInterval == interval) {
      return false;
    }

    _isSaving = true;
    _operationRevision++;
    final keepAliveLink = ref.keepAlive();
    final previousState = state;
    state = const AsyncLoading<AndroidWidgetUpdateInterval>().copyWithPrevious(
      previousState,
    );
    try {
      await ref
          .read(updateAndroidWidgetIntervalUsecaseProvider)
          .execute(interval);
      if (!ref.mounted) {
        return false;
      }
      state = AsyncData(interval);
      return true;
    } catch (_) {
      if (ref.mounted) {
        state = previousState;
      }
      rethrow;
    } finally {
      _isSaving = false;
      keepAliveLink.close();
    }
  }
}

class AndroidWidgetTargetGroupState extends Equatable {
  const AndroidWidgetTargetGroupState({
    required this.groups,
    required this.selectedGroupId,
  });

  final List<GroupDto> groups;
  final String? selectedGroupId;

  AndroidWidgetTargetGroupState copyWith({required String? selectedGroupId}) {
    return AndroidWidgetTargetGroupState(
      groups: groups,
      selectedGroupId: selectedGroupId,
    );
  }

  @override
  List<Object?> get props => [groups, selectedGroupId];
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
  bool _isSaving = false;
  int _operationRevision = 0;

  int get operationRevision => _operationRevision;

  @override
  Future<AndroidWidgetTargetGroupState> build() async {
    final groupsFuture = ref
        .read(getGroupsWithMembersUsecaseProvider)
        .execute(_member);
    final selectedGroupIdFuture = ref
        .read(androidWidgetCacheStorageProvider)
        .getTargetGroupId();
    final groups = await groupsFuture;
    final selectedGroupId = await selectedGroupIdFuture;

    return AndroidWidgetTargetGroupState(
      groups: groups,
      selectedGroupId: groups.any((group) => group.id == selectedGroupId)
          ? selectedGroupId
          : null,
    );
  }

  Future<bool> select(String? groupId) async {
    final currentState = state.value;
    if (_isSaving ||
        currentState == null ||
        currentState.selectedGroupId == groupId) {
      return false;
    }

    _isSaving = true;
    _operationRevision++;
    final keepAliveLink = ref.keepAlive();
    final previousState = state;
    state = const AsyncLoading<AndroidWidgetTargetGroupState>()
        .copyWithPrevious(previousState);
    try {
      if (groupId == null) {
        await ref.read(clearAndroidWidgetTargetGroupUsecaseProvider).execute();
      } else {
        await ref
            .read(selectAndroidWidgetTargetGroupUsecaseProvider)
            .execute(groupId);
      }
      if (!ref.mounted) {
        return false;
      }
      state = AsyncData(currentState.copyWith(selectedGroupId: groupId));
      return true;
    } catch (_) {
      if (ref.mounted) {
        state = previousState;
      }
      rethrow;
    } finally {
      _isSaving = false;
      keepAliveLink.close();
    }
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
    final selectedInterval = intervalState.value;
    if (selectedInterval == null) {
      return _buildLoadingOrRetry(
        hasError: intervalState.hasError,
        errorMessage: 'ウィジェット更新間隔を取得できませんでした',
        onRetry: () => ref.invalidate(androidWidgetUpdateIntervalProvider),
      );
    }

    return DropdownButtonFormField<AndroidWidgetUpdateInterval>(
      key: ValueKey((
        selectedInterval,
        ref
            .read(androidWidgetUpdateIntervalProvider.notifier)
            .operationRevision,
      )),
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
      onChanged: intervalState.isLoading
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
      return const Text('所属グループがありません');
    }

    return DropdownButtonFormField<String>(
      key: ValueKey((
        member.id,
        setting.selectedGroupId,
        ref.read(provider.notifier).operationRevision,
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
      onChanged: targetGroupState.isLoading
          ? null
          : (groupId) async {
              try {
                final saved = await ref.read(provider.notifier).select(groupId);
                if (!saved || !context.mounted) {
                  return;
                }
                final message = groupId == null
                    ? 'ウィジェット表示対象を解除しました'
                    : 'ウィジェット表示対象を保存しました';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              } catch (_) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ウィジェット表示対象を保存できませんでした')),
                );
              }
            },
    );
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
