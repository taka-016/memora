import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/presentation/shared/sheets/location_detail_panel_frame.dart';

class LocationDetailBottomSheet extends StatelessWidget {
  const LocationDetailBottomSheet({
    super.key,
    required this.location,
    required this.onClose,
    this.onPreviousLocation,
    this.onNextLocation,
  });

  final LocationDto location;
  final VoidCallback onClose;
  final VoidCallback? onPreviousLocation;
  final VoidCallback? onNextLocation;

  @override
  Widget build(BuildContext context) {
    final name = location.name?.isNotEmpty == true ? location.name! : '場所名未設定';
    return LocationDetailPanelFrame(
      panelKey: const Key('location_detail_bottom_sheet'),
      onClose: onClose,
      locationName: name,
      onPreviousLocation: onPreviousLocation,
      onNextLocation: onNextLocation,
      child: const SizedBox.shrink(),
    );
  }
}
