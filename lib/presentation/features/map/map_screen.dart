import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/map/map_pin_bottom_sheet.dart';
import 'package:memora/presentation/features/trip/trip_edit_modal.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/map_notifier.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';

class MapScreen extends ConsumerWidget {
  final bool isTestEnvironment;

  const MapScreen({super.key, this.isTestEnvironment = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMember = ref.watch(currentMemberNotifierProvider).member;
    if (currentMember == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final provider = mapNotifierProvider(currentMember);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final selectedGroup = state.selectedGroup;

    if (selectedGroup == null) {
      return _MapGroupSelection(
        state: state,
        onGroupSelected: (group) => unawaited(notifier.selectGroup(group)),
        onRetry: () => unawaited(notifier.loadGroups()),
      );
    }

    Future<void> handleTripTapped(TripEntryDto trip) async {
      final currentTrip = await notifier.loadTripDetail(trip.id);
      if (!context.mounted) {
        return;
      }
      final currentState = ref.read(provider);
      final group = currentState.groups
          .where((item) => item.id == currentTrip?.groupId)
          .firstOrNull;
      if (currentTrip == null || group == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('指定された旅行が見つかりませんでした')));
        return;
      }

      await showDialog<void>(
        barrierDismissible: false,
        context: context,
        builder: (dialogContext) => TripEditModal(
          groupId: currentTrip.groupId,
          groupMembers: group.members,
          tripEntry: currentTrip,
          year: currentTrip.year,
          isTestEnvironment: isTestEnvironment,
          onSave: (updatedTrip) async {
            await notifier.updateTripEntry(updatedTrip);
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('旅行を更新しました')));
            }
          },
        ),
      );
    }

    final mapViewType = isTestEnvironment
        ? MapViewType.placeholder
        : MapViewType.google;

    final mapView = KeyedSubtree(
      key: ValueKey(selectedGroup.id),
      child: MapViewFactory.create(mapViewType).createMapView(
        locations: state.locations,
        focusedLocation: state.locations.firstOrNull,
        topLeadingOverlay: _MapToolbar(
          groups: state.groups,
          selectedGroup: selectedGroup,
          onGroupSelected: (group) => unawaited(notifier.selectGroup(group)),
          isLoading: state.isGroupDataLoading,
          onReload: () => unawaited(notifier.retryGroupData()),
        ),
        locationDetailBuilder:
            (location, onClose, {onPreviousLocation, onNextLocation}) {
              final matchingLocations = state.locations
                  .where((item) => _hasSameCoordinate(item, location))
                  .toList(growable: false);
              final tripIds = matchingLocations
                  .map((item) => item.tripId)
                  .toSet();
              final matchingTrips = state.trips
                  .where((trip) => tripIds.contains(trip.id))
                  .toList(growable: false);
              return MapPinBottomSheet(
                location: location,
                trips: matchingTrips,
                onTripTapped: handleTripTapped,
                onClose: onClose,
                onPreviousLocation: onPreviousLocation,
                onNextLocation: onNextLocation,
              );
            },
        locationDetailBottomSheetHeight: MapPinBottomSheet.height,
        isReadOnly: true,
      ),
    );

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Stack(
        children: [
          mapView,
          if (state.isGroupDataLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.locationsStatus == MapLoadStatus.error ||
              state.tripsStatus == MapLoadStatus.error)
            _MapDataLoadErrorMessage(
              messages: [
                if (state.locationsStatus == MapLoadStatus.error)
                  '訪問場所の取得に失敗しました',
                if (state.tripsStatus == MapLoadStatus.error) '旅行情報の取得に失敗しました',
              ],
            )
          else if (state.locations.isEmpty)
            const _NoVisitLocationsMessage(),
        ],
      ),
    );
  }
}

class _MapToolbar extends StatelessWidget {
  const _MapToolbar({
    required this.groups,
    required this.selectedGroup,
    required this.onGroupSelected,
    required this.isLoading,
    required this.onReload,
  });

  final List<GroupDto> groups;
  final GroupDto selectedGroup;
  final ValueChanged<GroupDto> onGroupSelected;
  final bool isLoading;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _MapGroupSelector(
          groups: groups,
          selectedGroup: selectedGroup,
          onSelected: onGroupSelected,
        ),
        const Spacer(),
        _MapReloadButton(isLoading: isLoading, onReload: onReload),
      ],
    );
  }
}

class _MapReloadButton extends StatelessWidget {
  const _MapReloadButton({required this.isLoading, required this.onReload});

  final bool isLoading;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      key: const Key('map_reload_button'),
      tooltip: '再読み込み',
      onPressed: isLoading ? null : onReload,
      icon: const Icon(Icons.refresh),
    );
  }
}

class _MapGroupSelection extends StatelessWidget {
  const _MapGroupSelection({
    required this.state,
    required this.onGroupSelected,
    required this.onRetry,
  });

  final MapState state;
  final ValueChanged<GroupDto> onGroupSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('map_group_list'),
      child: switch (state.groupsStatus) {
        MapLoadStatus.initial || MapLoadStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        MapLoadStatus.error => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('エラーが発生しました', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('再読み込み')),
            ],
          ),
        ),
        MapLoadStatus.success when state.groups.isEmpty => const Center(
          child: Text('グループがありません', style: TextStyle(fontSize: 18)),
        ),
        MapLoadStatus.success => Column(
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
        ),
      },
    );
  }
}

class _MapGroupSelector extends StatelessWidget {
  const _MapGroupSelector({
    required this.groups,
    required this.selectedGroup,
    required this.onSelected,
  });

  final List<GroupDto> groups;
  final GroupDto selectedGroup;
  final ValueChanged<GroupDto> onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: PopupMenuButton<String>(
        key: const Key('map_group_selector'),
        tooltip: '表示するグループを選択',
        initialValue: selectedGroup.id,
        onSelected: (groupId) {
          onSelected(groups.firstWhere((group) => group.id == groupId));
        },
        itemBuilder: (context) {
          return [
            for (final group in groups)
              PopupMenuItem<String>(
                value: group.id,
                child: Text(group.name, overflow: TextOverflow.ellipsis),
              ),
          ];
        },
        child: Chip(
          visualDensity: VisualDensity.compact,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  selectedGroup.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoVisitLocationsMessage extends StatelessWidget {
  const _NoVisitLocationsMessage();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('このグループには訪問場所がありません'),
          ),
        ),
      ),
    );
  }
}

class _MapDataLoadErrorMessage extends StatelessWidget {
  const _MapDataLoadErrorMessage({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: Card(
          key: const Key('map_data_load_error'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [for (final message in messages) Text(message)],
            ),
          ),
        ),
      ),
    );
  }
}

bool _hasSameCoordinate(LocationDto left, LocationDto right) {
  return left.latitude == right.latitude && left.longitude == right.longitude;
}
