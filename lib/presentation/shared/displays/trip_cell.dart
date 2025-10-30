import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';

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
    if (trips.isEmpty) {
      return Container();
    }

    final textStyle = TextStyle(
      fontSize: 12.0,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return Container(
      height: availableHeight,
      width: availableWidth,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _buildTripList(constraints, textStyle);
        },
      ),
    );
  }

  Widget _buildTripList(BoxConstraints constraints, TextStyle textStyle) {
    final availableLines = (constraints.maxHeight / _itemHeight).floor();
    final remainingHeight = _itemHeight / 2;

    if (availableLines <= 0) {
      return Container();
    }

    if (trips.length <= availableLines) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: trips.map((trip) => _buildTripItem(trip, textStyle)).toList(),
      );
    } else {
      final displayCount =
          ((constraints.maxHeight - remainingHeight) / _itemHeight).floor();
      final remainingCount = trips.length - displayCount;

      final displayTrips = trips.take(displayCount).toList();
      final items = displayTrips
          .map((trip) => _buildTripItem(trip, textStyle))
          .toList();

      items.add(
        SizedBox(
          height: remainingHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('...他$remainingCount件', style: textStyle),
          ),
        ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      );
    }
  }

  Widget _buildTripItem(TripEntryDto trip, TextStyle textStyle) {
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
}
