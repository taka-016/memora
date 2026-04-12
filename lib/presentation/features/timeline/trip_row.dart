import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/timeline/timeline_destination_page_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_overflow_cell.dart';
import 'package:memora/presentation/features/trip/trip_management.dart';
import 'package:memora/presentation/notifiers/group_timeline_destination.dart';

class TripRow extends TimelineRowDefinition {
  const TripRow({
    required this.groupId,
    required this.initialHeight,
    required this.onDestinationSelected,
  });

  final String groupId;

  @override
  final double initialHeight;
  final ValueChanged<GroupTimelineDestination>? onDestinationSelected;

  @override
  String get fixedColumnLabel => '旅行';

  @override
  Color get backgroundColor => Colors.lightBlue.shade50;

  @override
  Iterable<TimelineDestinationPageDefinition> get destinationPageDefinitions =>
      const [_TripManagementDestinationPageDefinition()];

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    return _TripYearCell(
      groupId: groupId,
      year: year,
      refreshKey: rowContext.controller.refreshKey,
      availableHeight: rowContext.rowHeight,
      availableWidth: rowContext.layoutConfig.yearColumnWidth,
    );
  }

  @override
  VoidCallback? yearCellTapCallback(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    final callback = onDestinationSelected;
    if (callback == null) {
      return null;
    }

    return () => callback(
      GroupTimelineTripManagementDestination(groupId: groupId, year: year),
    );
  }
}

class _TripManagementDestinationPageDefinition
    extends TimelineDestinationPageDefinition {
  const _TripManagementDestinationPageDefinition();

  @override
  bool matches(GroupTimelineDestination destination) {
    return destination is GroupTimelineTripManagementDestination;
  }

  @override
  Widget buildPage({
    required BuildContext context,
    required GroupTimelineDestination destination,
    required VoidCallback onBackPressed,
  }) {
    final tripDestination =
        destination as GroupTimelineTripManagementDestination;
    return TripManagement(
      groupId: tripDestination.groupId,
      year: tripDestination.year,
      onBackPressed: onBackPressed,
    );
  }
}

final _tripEntriesProvider = FutureProvider.autoDispose
    .family<List<TripEntryDto>, _TripEntriesQuery>((ref, query) async {
      try {
        final getTripEntriesUsecase = ref.watch(getTripEntriesUsecaseProvider);
        return await getTripEntriesUsecase.execute(query.groupId, query.year);
      } catch (e, stack) {
        logger.e(
          'TripRow.loadTrips: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        return [];
      }
    });

class _TripYearCell extends ConsumerWidget {
  const _TripYearCell({
    required this.groupId,
    required this.year,
    required this.refreshKey,
    required this.availableHeight,
    required this.availableWidth,
  });

  final String groupId;
  final int year;
  final int refreshKey;
  final double availableHeight;
  final double availableWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref
        .watch(
          _tripEntriesProvider(
            _TripEntriesQuery(
              groupId: groupId,
              year: year,
              refreshKey: refreshKey,
            ),
          ),
        )
        .valueOrNull;

    return TripCell(
      trips: trips ?? const [],
      availableHeight: availableHeight,
      availableWidth: availableWidth,
    );
  }
}

class _TripEntriesQuery {
  const _TripEntriesQuery({
    required this.groupId,
    required this.year,
    required this.refreshKey,
  });

  final String groupId;
  final int year;
  final int refreshKey;

  @override
  bool operator ==(Object other) {
    return other is _TripEntriesQuery &&
        other.groupId == groupId &&
        other.year == year &&
        other.refreshKey == refreshKey;
  }

  @override
  int get hashCode => Object.hash(groupId, year, refreshKey);
}

class TripCell extends StatelessWidget {
  const TripCell({
    super.key,
    required this.trips,
    required this.availableHeight,
    required this.availableWidth,
  });

  static const double _itemHeight = 32.0;

  final List<TripEntryDto> trips;
  final double availableHeight;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    return TimelineOverflowCell<TripEntryDto>(
      items: trips,
      availableHeight: availableHeight,
      availableWidth: availableWidth,
      itemHeight: _itemHeight,
      itemBuilder: _buildTripItem,
    );
  }

  Widget _buildTripItem(TripEntryDto trip, TextStyle textStyle) {
    final formattedDate = _formatTripDate(trip);

    return SizedBox(
      height: _itemHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: Text(
              formattedDate,
              style: textStyle.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                trip.tripName ?? '旅行名未設定',
                style: textStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTripDate(TripEntryDto trip) {
    final startDate = trip.tripStartDate;
    if (startDate == null) {
      return '${trip.tripYear}年 (期間未設定)';
    }
    final month = startDate.month.toString().padLeft(2, '0');
    final day = startDate.day.toString().padLeft(2, '0');
    return '${startDate.year}/$month/$day';
  }
}
