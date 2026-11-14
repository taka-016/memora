import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';

part 'calendar_labels_notifier.g.dart';

class CalendarLabelsState {
  CalendarLabelsState({List<CalendarLabelDto> labels = const [], this.canManage = false, this.isLoading = false, this.isSaving = false, this.loadError = '', this.mutationError = ''}) : labels = List.unmodifiable(labels);
  final List<CalendarLabelDto> labels;
  final bool canManage;
  final bool isLoading;
  final bool isSaving;
  final String loadError;
  final String mutationError;
  CalendarLabelsState copyWith({List<CalendarLabelDto>? labels, bool? canManage, bool? isLoading, bool? isSaving, String? loadError, String? mutationError}) => CalendarLabelsState(labels: labels ?? this.labels, canManage: canManage ?? this.canManage, isLoading: isLoading ?? this.isLoading, isSaving: isSaving ?? this.isSaving, loadError: loadError ?? this.loadError, mutationError: mutationError ?? this.mutationError);
}

@riverpod
class CalendarLabelsNotifier extends _$CalendarLabelsNotifier {
  int _generation = 0;
  @override
  CalendarLabelsState build(String groupId) {
    ref.watch(currentMemberNotifierProvider.select((s) => s.member?.id));
    final generation = ++_generation;
    ref.onDispose(() => _generation++);
    Future.microtask(() { if (ref.mounted && generation == _generation) unawaited(load()); });
    return CalendarLabelsState();
  }
  Future<void> load() async {
    final generation = _generation;
    final memberId = ref.read(currentMemberNotifierProvider).member?.id;
    state = state.copyWith(isLoading: true, loadError: '');
    try {
      final group = await ref.read(getGroupWithMembersByIdUsecaseProvider).execute(groupId);
      final labels = await ref.read(getCalendarLabelsUsecaseProvider).execute(groupId);
      if (!ref.mounted || generation != _generation) return;
      final canManage = memberId != null && group != null && (group.ownerId == memberId || group.members.any((m) => m.memberId == memberId && m.isAdministrator));
      state = state.copyWith(labels: labels, canManage: canManage, isLoading: false);
    } catch (_) {
      if (ref.mounted && generation == _generation) state = state.copyWith(isLoading: false, canManage: false, loadError: '色ラベルを取得できませんでした。再試行してください');
    }
  }
  Future<bool> _mutate(Future<void> Function(String memberId) action) async {
    final memberId = ref.read(currentMemberNotifierProvider).member?.id;
    if (state.isSaving || state.isLoading || !state.canManage || memberId == null) return false;
    final generation = _generation;
    state = state.copyWith(isSaving: true, mutationError: '');
    try {
      await action(memberId);
      if (!ref.mounted || generation != _generation) return true;
      await load();
      if (ref.mounted && generation == _generation) state = state.copyWith(isSaving: false);
      return true;
    } catch (error) {
      if (ref.mounted && generation == _generation) state = state.copyWith(isSaving: false, mutationError: error is ApplicationValidationException ? error.message : '色ラベルを保存できませんでした。再試行してください');
      return false;
    }
  }
  Future<bool> saveLabel(CalendarLabelDto label) => _mutate((memberId) async {
    if (label.groupId != groupId) throw const ApplicationValidationException('同じグループの色ラベルを指定してください');
    await ref.read(calendarLabelManagementUsecaseProvider).save(label, memberId);
  });
  Future<bool> deleteLabel(String id, {int? expectedVersion}) => _mutate((memberId) => ref.read(calendarLabelManagementUsecaseProvider).delete(groupId, id, memberId, expectedVersion: expectedVersion));
  Future<bool> reorderLabels(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || newIndex < 0 || oldIndex >= state.labels.length || newIndex >= state.labels.length) return false;
    final ordered = state.labels.toList();
    ordered.insert(newIndex, ordered.removeAt(oldIndex));
    return _mutate((memberId) => ref.read(calendarLabelManagementUsecaseProvider).reorder(groupId, ordered.map((l) => l.id).toList(), memberId, expectedVersions: {for (final label in state.labels) if (label.version != null) label.id: label.version!}));
  }
}
