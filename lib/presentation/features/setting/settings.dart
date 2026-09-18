import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/android_widget/update_android_widget_interval_usecase.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/presentation/notifiers/backup/offline_backup_notifier.dart';

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
          ..._buildModeInformation(ref),
          if (ref.watch(appModeProvider) == AppMode.offline) ...[
            const SizedBox(height: 24),
            _buildOfflineBackupSection(context, ref),
          ],
          const SizedBox(height: 24),
          Text('Androidウィジェット', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildAndroidWidgetGroupSetting(context, ref, currentMemberState),
          const SizedBox(height: 16),
          _buildAndroidWidgetUpdateIntervalSetting(context, ref),
        ],
      ),
    );
  }

  List<Widget> _buildModeInformation(WidgetRef ref) {
    final capabilities = ref.watch(appCapabilitiesProvider);
    final online = capabilities
        .availability(AppFeature.authentication)
        .isAvailable;
    final storage = capabilities.availability(AppFeature.localData);
    return [
      Text(online ? 'オンラインモード' : 'オフラインモード'),
      const SizedBox(height: 8),
      Text(online ? '保存先: クラウド（Firestore）' : '保存先: この端末のアプリ内部ストレージ'),
      const SizedBox(height: 8),
      Text(
        online
            ? '利用可能機能: 年表・メンバー・グループ・旅行・タスク・旅程・DVCポイント・地図・場所検索・現在地・共有・招待'
            : '本人情報を端末内で復元できます。地図・場所検索・現在地・共有・招待は利用できません。',
      ),
      if (!storage.isAvailable) Text(storage.reason!),
      const SizedBox(height: 8),
      Text(
        online
            ? 'アプリを削除してもクラウドのデータは保持されます。'
            : 'バックアップ未作成時は、アプリ削除・データ消去・端末故障によりデータを復元できなくなります。',
      ),
    ];
  }

  Widget _buildOfflineBackupSection(BuildContext context, WidgetRef ref) {
    final state = ref.watch(offlineBackupNotifierProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('オフラインデータのバックアップ', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text('バックアップのパスワードを忘れた場合は復元できません。パスワードは端末に保存されません。'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: state.isWorking
                  ? null
                  : () => _createOfflineBackup(context, ref),
              child: const Text('バックアップを作成'),
            ),
            OutlinedButton(
              onPressed: state.isWorking
                  ? null
                  : () => _prepareOfflineRestore(context, ref),
              child: const Text('バックアップから復元'),
            ),
          ],
        ),
        if (state.isWorking) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Future<void> _createOfflineBackup(BuildContext context, WidgetRef ref) async {
    final password = await _showPasswordDialog(
      context,
      title: 'バックアップのパスワード',
      actionLabel: '保存先を選択',
      passwordKey: const Key('offline_backup_password'),
      confirmPassword: true,
    );
    if (password == null || !context.mounted) return;
    try {
      final saved = await ref
          .read(offlineBackupNotifierProvider.notifier)
          .create(password);
      if (!saved || !context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('オフラインデータをバックアップしました')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('バックアップを作成できませんでした')));
    }
  }

  Future<void> _prepareOfflineRestore(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final password = await _showPasswordDialog(
      context,
      title: 'バックアップのパスワード',
      actionLabel: 'バックアップを選択',
      passwordKey: const Key('offline_restore_password'),
    );
    if (password == null || !context.mounted) return;
    try {
      final prepared = await ref
          .read(offlineBackupNotifierProvider.notifier)
          .prepareRestore(password);
      if (!prepared || !context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('バックアップから復元'),
          content: const Text('現在のオフラインデータを全件置換します。この操作は取り消せません。復元しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('復元する'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      final restored = await ref
          .read(offlineBackupNotifierProvider.notifier)
          .restorePrepared();
      if (!restored || !context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('オフラインデータを復元しました')));
    } on OfflineBackupAuthenticationException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードが誤っているか、バックアップが破損しています')),
      );
    } on OfflineBackupUnsupportedVersionException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } on FormatException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('バックアップファイルを読み込めませんでした')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('オフラインデータを復元できませんでした')));
    }
  }

  Future<String?> _showPasswordDialog(
    BuildContext context, {
    required String title,
    required String actionLabel,
    required Key passwordKey,
    bool confirmPassword = false,
  }) async {
    var password = '';
    var confirmation = '';
    String? errorMessage;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: passwordKey,
                obscureText: true,
                onChanged: (value) => password = value,
                decoration: const InputDecoration(labelText: 'パスワード（8文字以上）'),
              ),
              if (confirmPassword) ...[
                const SizedBox(height: 8),
                TextField(
                  key: const Key('offline_backup_password_confirmation'),
                  obscureText: true,
                  onChanged: (value) => confirmation = value,
                  decoration: const InputDecoration(labelText: 'パスワード（確認）'),
                ),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                if (password.length < 8) {
                  setState(() => errorMessage = 'パスワードは8文字以上で入力してください');
                  return;
                }
                if (confirmPassword && password != confirmation) {
                  setState(() => errorMessage = '確認用パスワードが一致しません');
                  return;
                }
                Navigator.of(dialogContext).pop(password);
              },
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
    return result;
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
