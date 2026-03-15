import 'package:flutter/material.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';

class SelectVisitLocationView extends StatelessWidget {
  const SelectVisitLocationView({
    super.key,
    required this.pins,
    required this.isTestEnvironment,
    required this.bottomSheet,
    required this.onClose,
    this.selectedPin,
    this.onMapLongTapped,
    this.onSearchedLocationSelected,
    this.onPinTapped,
    this.onPinUpdated,
    this.onPinDeleted,
    this.closeButtonKey,
  });

  final List<PinDto> pins;
  final bool isTestEnvironment;
  final Widget bottomSheet;
  final VoidCallback onClose;
  final PinDto? selectedPin;
  final ValueChanged<Coordinate>? onMapLongTapped;
  final ValueChanged<LocationCandidateDto>? onSearchedLocationSelected;
  final Function(PinDto)? onPinTapped;
  final Function(PinDto)? onPinUpdated;
  final Function(String)? onPinDeleted;
  final Key? closeButtonKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMapHeader(),
        const SizedBox(height: 20),
        Expanded(child: Stack(children: [_buildMapView(), bottomSheet])),
      ],
    );
  }

  Widget _buildMapHeader() {
    return Row(
      children: [
        const Text(
          '訪問場所',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        IconButton(
          key: closeButtonKey,
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return isTestEnvironment ? _buildTestMapView() : _buildProductionMapView();
  }

  Widget _buildTestMapView() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: MapViewFactory.create(
          MapViewType.placeholder,
        ).createMapView(pins: const []),
      ),
    );
  }

  Widget _buildProductionMapView() {
    return MapViewFactory.create(MapViewType.google).createMapView(
      pins: pins,
      onMapLongTapped: onMapLongTapped,
      onSearchedLocationSelected: onSearchedLocationSelected,
      onPinTapped: onPinTapped,
      onPinUpdated: onPinUpdated,
      onPinDeleted: onPinDeleted,
      selectedPin: selectedPin,
    );
  }
}
