import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/features/timeline/refresh_timeline_callback.dart';
import 'package:memora/presentation/features/timeline/timeline.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_rows.dart';
import 'package:memora/presentation/notifiers/group_timeline_group_selection_notifier.dart';

int groupTimelineStackIndex({required String? groupId}) {
  return groupId == null ? 0 : 1;
}

class GroupTimelineNavigationView extends HookConsumerWidget {
  const GroupTimelineNavigationView({
    super.key,
    required this.currentMember,
    this.groupId,
  });

  final MemberDto currentMember;
  final String? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupSelectionState = ref.watch(
      groupTimelineGroupSelectionNotifierProvider,
    );
    final refreshTimeline = useRef<RefreshTimelineCallback?>(null);
    final autoSelectedGroups = useRef<List<GroupDto>?>(null);

    useEffect(() {
      if (groupSelectionState.status ==
              GroupTimelineGroupSelectionStatus.loaded &&
          groupSelectionState.groups.length == 1 &&
          autoSelectedGroups.value != groupSelectionState.groups &&
          groupId == null &&
          GoRouter.of(context).state.matchedLocation ==
              const GroupListRoute().location) {
        autoSelectedGroups.value = groupSelectionState.groups;
        Future.microtask(() {
          if (context.mounted) {
            GroupTimelineRoute(
              groupId: groupSelectionState.groups.single.id,
            ).go(context);
          }
        });
      }
      return null;
    }, [groupId, groupSelectionState.status, groupSelectionState.groups]);

    final selectedGroup = _findSelectedGroup(
      groupSelectionState.groups,
      groupId,
    );

    useEffect(() {
      if (groupId == null ||
          groupSelectionState.status !=
              GroupTimelineGroupSelectionStatus.loaded ||
          selectedGroup != null) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        const GroupListRoute().go(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('指定されたグループが見つかりませんでした')),
        );
      });
      return null;
    }, [groupId, groupSelectionState.status, selectedGroup]);

    final rowDefinitions = selectedGroup == null
        ? const <TimelineRowDefinition>[]
        : buildTimelineRows(
            groupWithMembers: selectedGroup,
            onTripSelected: (selectedGroupId, year) {
              unawaited(
                _openTripManagement(
                  context: context,
                  groupId: selectedGroupId,
                  year: year,
                  refreshTimeline: refreshTimeline,
                ),
              );
            },
            onDvcSelected: (selectedGroupId) {
              unawaited(
                _openDvcPointCalculation(
                  context: context,
                  groupId: selectedGroupId,
                  refreshTimeline: refreshTimeline,
                ),
              );
            },
          );

    if (groupId != null && selectedGroup == null) {
      if (groupSelectionState.status ==
          GroupTimelineGroupSelectionStatus.error) {
        return _buildGroupSelection(
          state: groupSelectionState,
          onGroupSelected: (group) {
            GroupTimelineRoute(groupId: group.id).go(context);
          },
          onRetry: () {
            unawaited(
              ref
                  .read(groupTimelineGroupSelectionNotifierProvider.notifier)
                  .load(currentMember),
            );
          },
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return IndexedStack(
      index: groupTimelineStackIndex(groupId: groupId),
      children: [
        _buildGroupSelection(
          state: groupSelectionState,
          onGroupSelected: (group) {
            GroupTimelineRoute(groupId: group.id).go(context);
          },
          onRetry: () {
            unawaited(
              ref
                  .read(groupTimelineGroupSelectionNotifierProvider.notifier)
                  .load(currentMember),
            );
          },
        ),
        selectedGroup == null
            ? const SizedBox.shrink()
            : Timeline(
                key: ValueKey(selectedGroup.id),
                groupWithMembers: selectedGroup,
                rowDefinitions: rowDefinitions,
                onBackPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    const GroupListRoute().go(context);
                  }
                },
                onSetRefreshCallback: (callback) {
                  refreshTimeline.value = callback;
                },
              ),
      ],
    );
  }

  Future<void> _openTripManagement({
    required BuildContext context,
    required String groupId,
    required int year,
    required ObjectRef<RefreshTimelineCallback?> refreshTimeline,
  }) async {
    await TripManagementRoute(groupId: groupId, year: year).push<void>(context);
    if (context.mounted) {
      await refreshTimeline.value?.call();
    }
  }

  Future<void> _openDvcPointCalculation({
    required BuildContext context,
    required String groupId,
    required ObjectRef<RefreshTimelineCallback?> refreshTimeline,
  }) async {
    await DvcPointCalculationRoute(groupId: groupId).push<void>(context);
    if (context.mounted) {
      await refreshTimeline.value?.call();
    }
  }

  GroupDto? _findSelectedGroup(List<GroupDto> groups, String? groupId) {
    if (groupId == null) {
      return null;
    }
    return groups.where((group) => group.id == groupId).firstOrNull;
  }

  Widget _buildGroupSelection({
    required GroupTimelineGroupSelectionState state,
    required ValueChanged<GroupDto> onGroupSelected,
    required VoidCallback onRetry,
  }) {
    switch (state.status) {
      case GroupTimelineGroupSelectionStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case GroupTimelineGroupSelectionStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(state.message, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('再読み込み')),
            ],
          ),
        );
      case GroupTimelineGroupSelectionStatus.loaded:
        if (state.groups.isEmpty) {
          return const Center(
            child: Text('グループがありません', style: TextStyle(fontSize: 18)),
          );
        }
        return Column(
          key: const Key('group_list'),
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'グループを選択',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: state.groups.length,
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  return ListTile(
                    title: Text(group.name),
                    subtitle: Text('${group.members.length}人のメンバー'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => onGroupSelected(group),
                  );
                },
              ),
            ),
          ],
        );
    }
  }
}
