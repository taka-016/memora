import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/startup_common_data_providers.dart';
import 'package:memora/presentation/notifiers/startup/startup_common_data_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/services/calendar/calendar_display_labels.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/group_providers.dart';

part 'calendar_event_input_notifier.g.dart';

class CalendarEventInputState {
  CalendarEventInputState({
    this.groupId,
    this.group,
    List<CalendarLabelDto> labels = const [],
    this.selectedLabelKey = 'group:',
    this.isLoading = false,
    this.error = '',
    this.original,
  }) : labels = List.unmodifiable(labels);
  final String? groupId;
  final GroupDto? group;
  final List<CalendarLabelDto> labels;
  final String selectedLabelKey;
  final bool isLoading;
  final String error;
  final CalendarEventDto? original;
  List<CalendarLabelDto> get displayLabels => group == null
      ? const []
      : buildCalendarDisplayLabels(
          group!,
          labels,
          events: [if (original?.groupId == groupId) original!],
        );
}

@riverpod
class CalendarEventInputNotifier extends _$CalendarEventInputNotifier {
  int _generation = 0;
  CalendarEventDto? _original;
  @override
  CalendarEventInputState build(Object session) {
    ref.onDispose(() => _generation++);
    if (_usesCommonData) {
      ref.listen(startupCommonDataNotifierProvider, (_, next) {
        final id = state.groupId;
        if (id != null) _applyCommon(id, next);
      });
    }
    return CalendarEventInputState();
  }

  Future<void> selectGroup(String? id, {CalendarEventDto? original}) async {
    if (state.groupId == id && state.group != null) return;
    _original ??= original;
    final key = original?.labelKey ?? 'group:';
    await _load(id, key);
  }

  bool get _usesCommonData =>
      ref.exists(startupCommonDataNotifierProvider) &&
      ref.read(startupCommonDataOwnerProvider) != null;

  Future<void> retry() async {
    if (_usesCommonData) {
      await ref.read(startupCommonDataNotifierProvider.notifier).refresh();
    }
    if (ref.mounted) await _load(state.groupId, state.selectedLabelKey);
  }

  void _applyCommon(String id, StartupCommonDataState common) {
    final group = common.data.groups?.where((g) => g.id == id).firstOrNull;
    final labels = common.data.labels[id];
    final loading =
        common.data.groups == null || (group != null && labels == null);
    final loadError = common.labelErrors[id] ?? common.error;
    state = CalendarEventInputState(
      groupId: id,
      group: group,
      labels: labels ?? const [],
      selectedLabelKey: state.selectedLabelKey,
      original: _original,
      isLoading: loading && loadError.isEmpty,
      error: common.groupsConfirmed && group == null
          ? '保存先グループが無効です。選び直してください'
          : loading
          ? loadError
          : '',
    );
  }

  Future<void> validateForSave() async {
    if (!_usesCommonData) return;
    final id = state.groupId;
    if (id == null) {
      throw const ApplicationValidationException('保存先グループを選択してください');
    }
    final generation = _generation;
    await ref.read(startupCommonDataNotifierProvider.notifier).ensureLatest(id);
    if (!ref.mounted || generation != _generation) {
      throw const ApplicationValidationException('保存先グループを確認して再度保存してください');
    }
    _applyCommon(id, ref.read(startupCommonDataNotifierProvider));
    if (state.group == null) {
      throw const ApplicationValidationException('保存先グループが無効です。選び直してください');
    }
    final selected = state.displayLabels
        .where((l) => l.id == state.selectedLabelKey)
        .firstOrNull;
    if (selected == null || !selected.isSelectable) {
      throw const ApplicationValidationException('色ラベルが無効です。選び直してください');
    }
  }

  Future<void> _load(String? id, String key) async {
    final generation = ++_generation;
    state = CalendarEventInputState(
      groupId: id,
      selectedLabelKey: key,
      isLoading: id != null,
      original: _original,
    );
    if (id == null) return;
    if (_usesCommonData) {
      _applyCommon(id, ref.read(startupCommonDataNotifierProvider));
      return;
    }
    try {
      final settings = ref.exists(calendarGroupSettingsNotifierProvider)
          ? ref.read(calendarGroupSettingsNotifierProvider)
          : null;
      final knownGroup = settings?.groupsReady == true
          ? settings!.groups.where((group) => group.id == id).firstOrNull
          : null;
      final calendar =
          knownGroup != null && ref.exists(calendarNotifierProvider(id))
          ? ref.read(calendarNotifierProvider(id))
          : null;
      final results = await Future.wait<Object?>([
        calendar?.group != null || knownGroup != null
            ? Future.value(calendar?.group ?? knownGroup)
            : ref.read(getGroupWithMembersByIdUsecaseProvider).execute(id),
        calendar?.hasLoadedLabels == true
            ? Future.value(calendar!.labels)
            : ref.read(getCalendarLabelsUsecaseProvider).execute(id),
      ]);
      if (!ref.mounted || generation != _generation) return;
      if (results[0] == null) throw StateError('グループが見つかりません');
      state = CalendarEventInputState(
        groupId: id,
        group: results[0] as GroupDto,
        labels: results[1] as List<CalendarLabelDto>,
        selectedLabelKey: state.selectedLabelKey,
        original: _original,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = CalendarEventInputState(
        groupId: id,
        selectedLabelKey: key,
        original: _original,
        error: 'グループと色ラベルを取得できませんでした。再試行してください',
      );
    }
  }

  void selectLabel(String key) {
    state = CalendarEventInputState(
      groupId: state.groupId,
      group: state.group,
      labels: state.labels,
      selectedLabelKey: key,
      original: _original,
      isLoading: state.isLoading,
      error: state.error,
    );
  }
}
