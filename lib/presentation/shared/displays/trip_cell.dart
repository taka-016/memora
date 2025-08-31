import 'package:flutter/material.dart';
import 'package:memora/domain/entities/trip_entry.dart';

class TripCell extends StatelessWidget {
  static const double _itemHeight = 32.0;

  final List<TripEntry> trips;
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
    if (trips.isEmpty) {
      return Container();
    }

    return Container(
      height: availableHeight,
      width: availableWidth,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: _buildTripList(),
    );
  }

  Widget _buildTripList() {
    final textStyle = const TextStyle(fontSize: 12.0);

    final availableLines = ((availableHeight) / (_itemHeight)).floor();

    if (availableLines <= 0) {
      return Container();
    }

    if (trips.length < availableLines) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: trips.map((trip) => _buildTripItem(trip, textStyle)).toList(),
      );
    } else {
      final displayCount = availableLines - 1;
      final remainingCount = trips.length - displayCount;

      final displayTrips = trips.take(displayCount).toList();
      final items = displayTrips
          .map((trip) => _buildTripItem(trip, textStyle))
          .toList();

      items.add(Text('...他$remainingCount件', style: textStyle));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      );
    }
  }

  Widget _buildTripItem(TripEntry trip, TextStyle style) {
    final year = trip.tripStartDate.year;
    final month = trip.tripStartDate.month.toString().padLeft(2, '0');
    final day = trip.tripStartDate.day.toString().padLeft(2, '0');
    final formattedDate = '$year/$month/$day';

    return SizedBox(
      height: _itemHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: Text(
              formattedDate,
              style: style.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                trip.tripName ?? '旅行名未設定',
                style: style,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
