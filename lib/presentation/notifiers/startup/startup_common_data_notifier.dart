import 'package:memora/application/dtos/group/group_dto.dart';

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/models/startup_common_data.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/startup_common_data_providers.dart';

part 'startup_common_data_notifier.g.dart';

class StartupCommonDataState {
  StartupCommonDataState({
    StartupCommonData? data,
    this.groupsConfirmed = false,
    Set<String> labelsConfirmed = const {},
    this.error = '',
    Map<String, String> labelErrors = const {},
  }) : labelErrors = Map.unmodifiable(labelErrors),
       data = data ?? StartupCommonData(),
       labelsConfirmed = Set.unmodifiable(labelsConfirmed);
  final StartupCommonData data;
  final bool groupsConfirmed;
  final Set<String> labelsConfirmed;
  final String error;
  final Map<String, String> labelErrors;
}

@Riverpod(keepAlive: true)
class StartupCommonDataNotifier extends _$StartupCommonDataNotifier {
  int _generation = 0;
  Future<void>? _initializing;
  Future<void>? _groupsRequest;
  final Map<String, Future<void>> _labelRequests = {};
  Future<void> _writing = Future.value();

  @override
  StartupCommonDataState build() {
    final owner = ref.watch(startupCommonDataOwnerProvider);
    final member = ref.watch(startupCommonDataMemberIdProvider);
    final generation = ++_generation;
    _groupsRequest = null;
    _labelRequests.clear();
    _initializing = null;
    ref.onDispose(() => _generation++);
    if (owner != null && member != null) {
      _initializing = Future.microtask(() => _initialize(owner, generation));
    }
    return StartupCommonDataState();
  }

  bool _current(int generation) => ref.mounted && generation == _generation;

  Future<void> _initialize(String owner, int generation) async {
    try {
      final cached = await ref
          .read(startupCommonDataStorageProvider)
          .load(owner);
      if (!_current(generation)) return;
      if (cached != null) state = StartupCommonDataState(data: cached);
    } catch (_) {
      // 読み出せないキャッシュは使わず、通常の初回取得へ進む。
    }
    if (_current(generation)) unawaited(_refresh(generation));
  }

  Future<void> refresh() async {
    final generation = _generation;
    await _initializing;
    if (_current(generation)) await _refresh(generation);
  }

  Future<void> refreshAfterChange() async {
    final generation = _generation;
    await _initializing;
    await _groupsRequest;
    if (_current(generation)) await _refresh(generation);
  }

  Future<void> _refresh(int generation) async {
    await _loadGroups();
    if (!_current(generation) || !state.groupsConfirmed) return;
    await Future.wait([
      for (final group in state.data.groups!)
        if (!state.labelsConfirmed.contains(group.id)) _loadLabels(group.id),
    ]);
  }

  Future<List<GroupDto>> availableGroups() async {
    final generation = _generation;
    await _initializing;
    if (!_current(generation)) {
      throw const ApplicationValidationException('利用者が変わりました。再度開いてください');
    }
    if (state.data.groups == null) {
      await _loadGroups();
      if (_current(generation) && state.groupsConfirmed) {
        for (final group in state.data.groups!) {
          if (!state.labelsConfirmed.contains(group.id)) {
            unawaited(_loadLabels(group.id));
          }
        }
      }
    }
    if (!_current(generation) || state.data.groups == null) {
      throw const ApplicationValidationException('グループを取得できませんでした。再試行してください');
    }
    return state.data.groups!;
  }

  Future<void> ensureLatest(String groupId) async {
    final generation = _generation;
    await _initializing;
    if (!_current(generation)) {
      throw const ApplicationValidationException('利用者が変わりました。再度開いてください');
    }
    if (!state.groupsConfirmed) await _loadGroups();
    if (!_current(generation) || !state.groupsConfirmed) {
      throw const ApplicationValidationException(
        '最新情報を取得できませんでした。入力を残したまま再度保存してください',
      );
    }
    if (!state.data.groups!.any((group) => group.id == groupId)) {
      throw const ApplicationValidationException('保存先グループが無効です。選び直してください');
    }
    if (!state.labelsConfirmed.contains(groupId)) await _loadLabels(groupId);
    if (!_current(generation) || !state.labelsConfirmed.contains(groupId)) {
      throw const ApplicationValidationException(
        '最新情報を取得できませんでした。入力を残したまま再度保存してください',
      );
    }
  }

  Future<void> _loadGroups() {
    if (_groupsRequest != null) return _groupsRequest!;
    final owner = ref.read(startupCommonDataOwnerProvider);
    final member = ref.read(startupCommonDataMemberIdProvider);
    if (owner == null || member == null) return Future.value();
    final generation = _generation;
    state = StartupCommonDataState(
      data: state.data,
      labelErrors: state.labelErrors,
    );
    final operation = _fetchGroups(owner, member, generation).whenComplete(() {
      if (_current(generation)) _groupsRequest = null;
    });
    _groupsRequest = operation;
    return operation;
  }

  Future<void> _fetchGroups(String owner, String member, int generation) async {
    try {
      final groups = await ref
          .read(startupCommonDataSourceProvider)
          .loadGroups(member);
      if (!_current(generation)) return;
      final ids = groups.map((g) => g.id).toSet();
      state = StartupCommonDataState(
        data: StartupCommonData(
          groups: groups,
          labels: {
            for (final entry in state.data.labels.entries)
              if (ids.contains(entry.key)) entry.key: entry.value,
          },
        ),
        groupsConfirmed: true,
        labelsConfirmed: state.labelsConfirmed.intersection(ids),
        labelErrors: {
          for (final entry in state.labelErrors.entries)
            if (ids.contains(entry.key)) entry.key: entry.value,
        },
      );
      await _persist(owner, generation);
    } catch (_) {
      if (_current(generation)) {
        state = StartupCommonDataState(
          data: state.data,
          labelsConfirmed: state.labelsConfirmed,
          error: '共通データの最新情報を取得できませんでした',
          labelErrors: state.labelErrors,
        );
      }
    }
  }

  Future<void> refreshLabels(String groupId) async {
    final generation = _generation;
    await _initializing;
    if (!_current(generation)) return;
    await _labelRequests[groupId];
    if (!_current(generation)) return;
    if (state.data.groups == null) await _loadGroups();
    if (!_current(generation) ||
        state.data.groups?.any((g) => g.id == groupId) != true) {
      return;
    }
    await _loadLabels(groupId);
  }

  Future<void> _loadLabels(String id) {
    if (_labelRequests[id] != null) return _labelRequests[id]!;
    final owner = ref.read(startupCommonDataOwnerProvider);
    if (owner == null) return Future.value();
    state = StartupCommonDataState(
      data: state.data,
      groupsConfirmed: state.groupsConfirmed,
      labelsConfirmed: state.labelsConfirmed.difference({id}),
      error: state.error,
      labelErrors: {...state.labelErrors}..remove(id),
    );
    final generation = _generation;
    final operation = _fetchLabels(owner, id, generation).whenComplete(() {
      if (_current(generation)) _labelRequests.remove(id);
    });
    _labelRequests[id] = operation;
    return operation;
  }

  Future<void> _fetchLabels(String owner, String id, int generation) async {
    try {
      final labels = await ref
          .read(startupCommonDataSourceProvider)
          .loadLabels(id);
      if (!_current(generation) || !state.data.groups!.any((g) => g.id == id)) {
        return;
      }
      state = StartupCommonDataState(
        data: StartupCommonData(
          groups: state.data.groups,
          labels: {...state.data.labels, id: labels},
        ),
        groupsConfirmed: state.groupsConfirmed,
        labelsConfirmed: {...state.labelsConfirmed, id},
        error: state.error,
        labelErrors: {...state.labelErrors}..remove(id),
      );
      await _persist(owner, generation);
    } catch (_) {
      if (_current(generation)) {
        state = StartupCommonDataState(
          data: state.data,
          groupsConfirmed: state.groupsConfirmed,
          labelsConfirmed: state.labelsConfirmed.difference({id}),
          error: state.error,
          labelErrors: {...state.labelErrors, id: '色ラベルの最新情報を取得できませんでした'},
        );
      }
    }
  }

  Future<void> _persist(String owner, int generation) {
    final data = state.data;
    final storage = ref.read(startupCommonDataStorageProvider);
    return _writing = (() async {
      await _writing;
      if (!_current(generation)) return;
      try {
        await storage.save(owner, data);
      } catch (_) {
        // キャッシュの書き込み失敗は、最新情報の取得成功とは分けて扱う。
      }
    })();
  }
}
