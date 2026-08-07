import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/presentation/features/timeline/refresh_timeline_callback.dart';
import 'package:memora/presentation/features/timeline/timeline.dart';
import 'package:memora/presentation/features/timeline/timeline_destination_page_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_rows.dart';
import 'package:memora/presentation/notifiers/group_timeline_group_selection_notifier.dart';
import 'package:memora/presentation/notifiers/group_timeline_navigation_notifier.dart';

class GroupTimelineNavigationView extends HookConsumerWidget {
  const GroupTimelineNavigationView({super.key, required this.currentMember});

  final MemberDto currentMember;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(groupTimelineNavigationNotifierProvider);
    final groupSelectionState = ref.watch(
      groupTimelineGroupSelectionNotifierProvider,
    );
    final navigationNotifier = ref.read(
      groupTimelineNavigationNotifierProvider.notifier,
    );
    final refreshTimeline = useRef<RefreshTimelineCallback?>(null);
    final previousDestination = useRef<GroupTimelineDestination?>(null);
    final autoSelectedGroups = useRef<List<GroupDto>?>(null);
    final destination = navigationState.destination;

    useEffect(() {
      final previous = previousDestination.value;
      previousDestination.value = destination;
      if (previous is! GroupTimelineOverviewDestination &&
          previous is! GroupTimelineGroupListDestination &&
          destination is GroupTimelineOverviewDestination) {
        final callback = refreshTimeline.value;
        if (callback != null) {
          unawaited(callback());
        }
      }
      return null;
    }, [destination]);

    useEffect(() {
      if (groupSelectionState.status ==
              GroupTimelineGroupSelectionStatus.loaded &&
          groupSelectionState.groups.length == 1 &&
          autoSelectedGroups.value != groupSelectionState.groups) {
        autoSelectedGroups.value = groupSelectionState.groups;
        if (destination is GroupTimelineGroupListDestination) {
          Future.microtask(() {
            navigationNotifier.showGroupTimeline(
              groupSelectionState.groups.single.id,
            );
          });
        }
      }
      return null;
    }, [destination, groupSelectionState.status, groupSelectionState.groups]);

    final selectedGroup = _findSelectedGroup(
      groupSelectionState.groups,
      destination.groupId,
    );
    final rowDefinitions = selectedGroup == null
        ? const <TimelineRowDefinition>[]
        : buildTimelineRows(
            groupWithMembers: selectedGroup,
            onDestinationSelected: navigationNotifier.showDestination,
          );
    final pageDefinitions = rowDefinitions
        .expand((definition) => definition.destinationPageDefinitions)
        .toList(growable: false);

    if (destination is! GroupTimelineGroupListDestination &&
        selectedGroup == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return IndexedStack(
      index: navigationNotifier.getStackIndex(),
      children: [
        _buildGroupSelection(
          state: groupSelectionState,
          onGroupSelected: (group) {
            navigationNotifier.showGroupTimeline(group.id);
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
                onBackPressed: navigationNotifier.showGroupList,
                onSetRefreshCallback: (callback) {
                  refreshTimeline.value = callback;
                },
              ),
        _buildDestinationPage(
          context: context,
          destination: destination,
          pageDefinitions: pageDefinitions,
          expectedType: GroupTimelineTripManagementDestination,
          onBackPressed: navigationNotifier.backToTimeline,
        ),
        _buildDestinationPage(
          context: context,
          destination: destination,
          pageDefinitions: pageDefinitions,
          expectedType: GroupTimelineDvcPointCalculationDestination,
          onBackPressed: navigationNotifier.backToTimeline,
        ),
      ],
    );
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

  Widget _buildDestinationPage({
    required BuildContext context,
    required GroupTimelineDestination destination,
    required List<TimelineDestinationPageDefinition> pageDefinitions,
    required Type expectedType,
    required VoidCallback onBackPressed,
  }) {
    if (destination.runtimeType != expectedType) {
      return const SizedBox.shrink();
    }
    final definition = pageDefinitions
        .where((definition) => definition.matches(destination))
        .firstOrNull;
    if (definition == null) {
      return const SizedBox.shrink();
    }
    return definition.buildPage(
      context: context,
      destination: destination,
      onBackPressed: onBackPressed,
    );
  }
}
