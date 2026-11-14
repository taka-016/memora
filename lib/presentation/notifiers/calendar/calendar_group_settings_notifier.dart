import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/models/calendar_group_settings.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/composition_root/providers/calendar_group_settings_providers.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';

part 'calendar_group_settings_notifier.g.dart';

class CalendarGroupSettingsState {
  CalendarGroupSettingsState({CalendarGroupSettings? settings, List<GroupDto> groups = const [], this.groupsReady = false, this.isLoading = true, this.isSaving = false, this.error = '', this.loadFailed = false})
    : settings = settings ?? CalendarGroupSettings(), groups = List.unmodifiable(groups);
  final CalendarGroupSettings settings;
  final List<GroupDto> groups;
  final bool groupsReady;
  final bool isLoading;
  final bool isSaving;
  final String error;
  final bool loadFailed;
  bool get canUseSettings => !isLoading && !loadFailed;
  CalendarGroupSettings get effectiveSettings => settings.retainGroups(groups.map((g) => g.id).toSet());
  CalendarGroupSettingsState copyWith({CalendarGroupSettings? settings, List<GroupDto>? groups, bool? groupsReady, bool? isLoading, bool? isSaving, String? error, bool? loadFailed}) => CalendarGroupSettingsState(
    settings: settings ?? this.settings, groups: groups ?? this.groups, groupsReady: groupsReady ?? this.groupsReady,
    isLoading: isLoading ?? this.isLoading, isSaving: isSaving ?? this.isSaving, error: error ?? this.error, loadFailed: loadFailed ?? this.loadFailed,
  );
}

@Riverpod(keepAlive: true)
class CalendarGroupSettingsNotifier extends _$CalendarGroupSettingsNotifier {
  int _generation = 0;
  int _loadRequest = 0;
  String? _owner;
  @override
  CalendarGroupSettingsState build() {
    final generation = ++_generation;
    _owner = ref.watch(calendarSettingsOwnerProvider);
    final memberId = ref.watch(calendarSettingsMemberIdProvider);
    ref.onDispose(() => _generation++);
    void receive(GroupTimelineGroupSelectionState selection) {
      if (!ref.mounted || generation != _generation || selection.memberId != memberId) return;
      if (selection.status == GroupTimelineGroupSelectionStatus.loaded) {
        state = state.copyWith(groups: selection.groups, groupsReady: true);
      } else {
        state = state.copyWith(groupsReady: false);
      }
    }
    ref.listen(groupTimelineGroupSelectionNotifierProvider, (_, next) => receive(next));
    final selection = ref.read(groupTimelineGroupSelectionNotifierProvider);
    Future.microtask(() {
      if (!ref.mounted || generation != _generation) return;
      receive(selection);
      unawaited(reload());
    });
    return CalendarGroupSettingsState();
  }

  Future<void> reload() async {
    final owner = _owner;
    if (owner == null || state.isSaving) return;
    final generation = _generation;
    final request = ++_loadRequest;
    state = state.copyWith(isLoading: true, error: '');
    try {
      final settings = await ref.read(calendarGroupSettingsStorageProvider).load(owner);
      if (!ref.mounted || generation != _generation || request != _loadRequest) return;
      state = state.copyWith(settings: settings, isLoading: false, loadFailed: false);
    } catch (_) {
      if (!ref.mounted || generation != _generation || request != _loadRequest) return;
      state = state.copyWith(isLoading: false, loadFailed: true, error: 'グループ設定を取得できませんでした。再試行してください');
    }
  }

  Future<bool> setVisibleGroups(Set<String> ids) => _save(CalendarGroupSettings(visibleGroupIds: ids, defaultGroupId: state.settings.defaultGroupId));
  Future<bool> setDefaultGroup(String? id) => _save(CalendarGroupSettings(visibleGroupIds: state.settings.visibleGroupIds, defaultGroupId: id));
  Future<bool> _save(CalendarGroupSettings settings) async {
    final owner = _owner;
    if (owner == null || !state.canUseSettings || state.isSaving || !state.groupsReady) return false;
    final allowed = state.groups.map((g) => g.id).toSet();
    if (!allowed.containsAll(settings.visibleGroupIds.difference(state.settings.visibleGroupIds)) ||
      (settings.defaultGroupId != null && settings.defaultGroupId != state.settings.defaultGroupId && !allowed.contains(settings.defaultGroupId))) return false;
    final generation = _generation;
    state = state.copyWith(isSaving: true, error: '');
    try {
      await ref.read(calendarGroupSettingsStorageProvider).save(owner, settings);
      if (!ref.mounted || generation != _generation) return false;
      state = state.copyWith(settings: settings, isSaving: false);
      return true;
    } catch (_) {
      if (ref.mounted && generation == _generation) state = state.copyWith(isSaving: false, error: 'グループ設定を保存できませんでした。再試行してください');
      return false;
    }
  }
}
