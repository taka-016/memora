import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/services/calendar/calendar_display_labels.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/group_providers.dart';

part 'calendar_event_input_notifier.g.dart';

class CalendarEventInputState {
  CalendarEventInputState({this.groupId, this.group, List<CalendarLabelDto> labels = const [], this.selectedLabelKey = 'group:', this.isLoading = false, this.error = '', this.original}) : labels = List.unmodifiable(labels);
  final String? groupId;
  final GroupDto? group;
  final List<CalendarLabelDto> labels;
  final String selectedLabelKey;
  final bool isLoading;
  final String error;
  final CalendarEventDto? original;
  List<CalendarLabelDto> get displayLabels => group == null ? const [] : buildCalendarDisplayLabels(group!, labels, events: [if (original?.groupId == groupId) original!]);
}

@riverpod
class CalendarEventInputNotifier extends _$CalendarEventInputNotifier {
  int _generation = 0;
  CalendarEventDto? _original;
  @override
  CalendarEventInputState build(Object session) {
    ref.onDispose(() => _generation++);
    return CalendarEventInputState();
  }
  Future<void> selectGroup(String? id, {CalendarEventDto? original}) async {
    _original ??= original;
    final key = original?.labelKey ?? 'group:';
    await _load(id, key);
  }
  Future<void> retry() => _load(state.groupId, state.selectedLabelKey);
  Future<void> _load(String? id, String key) async {
    final generation = ++_generation;
    state = CalendarEventInputState(groupId: id, selectedLabelKey: key, isLoading: id != null, original: _original);
    if (id == null) return;
    try {
      final results = await Future.wait<Object?>([
        ref.read(getGroupWithMembersByIdUsecaseProvider).execute(id),
        ref.read(getCalendarLabelsUsecaseProvider).execute(id),
      ]);
      if (!ref.mounted || generation != _generation) return;
      if (results[0] == null) throw StateError('グループが見つかりません');
      state = CalendarEventInputState(groupId: id, group: results[0] as GroupDto, labels: results[1] as List<CalendarLabelDto>, selectedLabelKey: key, original: _original);
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = CalendarEventInputState(groupId: id, selectedLabelKey: key, original: _original, error: 'グループと色ラベルを取得できませんでした。再試行してください');
    }
  }
  void selectLabel(String key) {
    state = CalendarEventInputState(groupId: state.groupId, group: state.group, labels: state.labels, selectedLabelKey: key, original: _original, isLoading: state.isLoading, error: state.error);
  }
}
