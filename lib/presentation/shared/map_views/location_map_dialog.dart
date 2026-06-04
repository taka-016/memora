import 'package:flutter/material.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/shared/map_views/map_view_builder.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';

class LocationMapDialog extends StatelessWidget {
  const LocationMapDialog({
    super.key,
    required this.dialogKey,
    required this.mapViewType,
    required this.locations,
    this.onMapLongTapped,
    this.onSearchedLocationSelected,
    this.onLocationTapped,
    this.selectedLocation,
    this.highlightSelectedLocation = false,
    this.locationDetailBuilder,
    this.tripStartDate,
    this.isReadOnly = false,
  });

  final Key dialogKey;
  final MapViewType mapViewType;
  final List<LocationDto> locations;
  final ValueChanged<Coordinate>? onMapLongTapped;
  final ValueChanged<LocationCandidateDto>? onSearchedLocationSelected;
  final ValueChanged<LocationDto>? onLocationTapped;
  final LocationDto? selectedLocation;
  final bool highlightSelectedLocation;
  final LocationDetailBuilder? locationDetailBuilder;
  final DateTime? tripStartDate;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: const RoundedRectangleBorder(),
      child: SizedBox(
        key: dialogKey,
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: '閉じる',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            Expanded(
              child: MapViewFactory.create(mapViewType).createMapView(
                locations: locations,
                onMapLongTapped: onMapLongTapped,
                onSearchedLocationSelected: onSearchedLocationSelected,
                onLocationTapped: onLocationTapped,
                selectedLocation: selectedLocation,
                highlightSelectedLocation: highlightSelectedLocation,
                locationDetailBuilder: locationDetailBuilder,
                tripStartDate: tripStartDate,
                isReadOnly: isReadOnly,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
