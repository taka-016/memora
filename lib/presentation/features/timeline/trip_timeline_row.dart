import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_overflow_cell.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';

class TripTimelineRow extends TimelineRowDefinition {
  const TripTimelineRow({
    required super.initialHeight,
    this.onTripManagementSelected,
  }) : super(rowId: 'trip', fixedColumnLabel: '旅行');

  final void Function(String groupId, int year)? onTripManagementSelected;

  @override
  Color? backgroundColor(BuildContext context) => Colors.lightBlue.shade50;

  @override
  Widget buildYearCell({
    required BuildContext context,
    required TimelineRowContext rowContext,
    required int year,
    required double rowHeight,
    required double yearColumnWidth,
  }) {
    final trips = rowContext.tripsByYear[year] ?? [];
    return _TripTimelineCell(
      trips: trips,
      availableHeight: rowHeight,
      availableWidth: yearColumnWidth,
    );
  }

  @override
  VoidCallback? onYearCellTap({
    required BuildContext context,
    required TimelineRowContext rowContext,
    required int year,
  }) {
    if (onTripManagementSelected == null) {
      return null;
    }
    return () => onTripManagementSelected!(rowContext.groupId, year);
  }
}

class _TripTimelineCell extends StatelessWidget {
  const _TripTimelineCell({
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
