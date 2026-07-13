import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/shared/sheets/location_detail_panel_frame.dart';

class MapPinBottomSheet extends StatelessWidget {
  const MapPinBottomSheet({
    super.key,
    required this.location,
    required this.trips,
    required this.hasTripLoadError,
    required this.onTripTapped,
    required this.onClose,
    this.onPreviousLocation,
    this.onNextLocation,
  });

  final LocationDto location;
  final List<TripEntryDto> trips;
  final bool hasTripLoadError;
  final ValueChanged<TripEntryDto> onTripTapped;
  final VoidCallback onClose;
  final VoidCallback? onPreviousLocation;
  final VoidCallback? onNextLocation;

  @override
  Widget build(BuildContext context) {
    final locationName = location.name?.isNotEmpty == true
        ? location.name!
        : '場所名未設定';
    return LocationDetailPanelFrame(
      panelKey: const Key('location_detail_bottom_sheet'),
      onClose: onClose,
      height: 280,
      locationName: locationName,
      onPreviousLocation: onPreviousLocation,
      onNextLocation: onNextLocation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '訪問した旅行',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          SizedBox(
            key: const Key('map_pin_trip_list_region'),
            height: 120,
            child: _buildTripList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTripList() {
    if (hasTripLoadError) {
      return const Center(child: Text('旅行情報の取得に失敗しました'));
    }
    if (trips.isEmpty) {
      return const Center(child: Text('この場所を訪問した旅行はありません'));
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: trips.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final trip = trips[index];
        final tripName = trip.name?.isNotEmpty == true ? trip.name! : '旅行名未設定';
        return ListTile(
          key: Key('map_pin_trip_${trip.id}'),
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(tripName),
          subtitle: Text(_formatStartYearMonth(trip.startDate)),
          onTap: () => onTripTapped(trip),
        );
      },
    );
  }

  String _formatStartYearMonth(DateTime? startDate) {
    if (startDate == null) {
      return '開始年月未設定';
    }
    return '${startDate.year}年${startDate.month}月';
  }
}
