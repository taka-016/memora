import 'package:flutter/material.dart';
import 'package:memora/domain/entities/trip_entry.dart';

class TripDisplayWidget extends StatelessWidget {
  final List<TripEntry> trips;
  final double availableHeight;
  final double availableWidth;

  const TripDisplayWidget({
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
    const itemHeight = 16.0; // 1行の高さ
    const spacing = 2.0; // 行間

    // 表示可能な行数を計算
    final availableLines = ((availableHeight - 4.0) / (itemHeight + spacing))
        .floor();

    if (availableLines <= 0) {
      return Container();
    }

    if (trips.length <= availableLines) {
      // すべて表示可能
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: trips.map((trip) => _buildTripItem(trip, textStyle)).toList(),
      );
    } else {
      // 省略表示が必要
      final displayCount = availableLines - 1; // 省略表示用の行を確保
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
    final formattedDate =
        '${trip.tripStartDate.year}/${trip.tripStartDate.month.toString().padLeft(2, '0')}';
    final displayText = trip.tripName != null
        ? '${trip.tripName} $formattedDate'
        : formattedDate;

    return Text(
      displayText,
      style: style,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
