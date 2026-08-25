import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_row_load_error.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_overflow_cell.dart';
import 'package:memora/presentation/features/timeline/timeline_trip_entries_provider.dart';

class TripRow extends TimelineRowDefinition {
  const TripRow({
    required this.groupId,
    required this.initialHeight,
    required this.onTripSelected,
  });

  final String groupId;

  @override
  final double initialHeight;
  final void Function(String groupId, int year)? onTripSelected;

  @override
  String get fixedColumnLabel => '旅行';

  @override
  Color get backgroundColor => Colors.lightBlue.shade50;

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    return _TripYearCell(
      groupId: groupId,
      year: year,
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
    final callback = onTripSelected;
    if (callback == null) {
      return null;
    }

    return () => callback(groupId, year);
  }
}

class _TripYearCell extends ConsumerWidget {
  const _TripYearCell({
    required this.groupId,
    required this.year,
    required this.availableHeight,
    required this.availableWidth,
  });

  final String groupId;
  final int year;
  final double availableHeight;
  final double availableWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = TimelineTripEntriesQuery(groupId: groupId, year: year);
    return ref
        .watch(timelineTripEntriesProvider(query))
        .when(
          data: (trips) => TripCell(
            trips: trips,
            availableHeight: availableHeight,
            availableWidth: availableWidth,
          ),
          error: (_, _) => TimelineRowLoadError(
            retryButtonKey: Key('timeline_trip_retry_$year'),
            onRetry: () => ref.invalidate(timelineTripEntriesProvider(query)),
          ),
          loading: () => const SizedBox.expand(),
        );
  }
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
                trip.name ?? '旅行名未設定',
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
    final startDate = trip.startDate;
    if (startDate == null) {
      return '${trip.year}年 (期間未設定)';
    }
    final month = startDate.month.toString().padLeft(2, '0');
    final day = startDate.day.toString().padLeft(2, '0');
    return '${startDate.year}/$month/$day';
  }
}
