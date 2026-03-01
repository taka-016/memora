import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_overflow_cell.dart';

class TripCell extends StatelessWidget {
  static const double _itemHeight = 32.0;

  final List<TripEntryDto> trips;
  final double availableHeight;
  final double availableWidth;

  const TripCell({
    super.key,
    required this.trips,
    required this.availableHeight,
    required this.availableWidth,
  });

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
