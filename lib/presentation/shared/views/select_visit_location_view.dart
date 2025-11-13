import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/domain/value_objects/location.dart';
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
    this.onMarkerTapped,
    this.onMarkerUpdated,
    this.onMarkerDeleted,
    this.closeButtonKey,
  });

  final List<PinDto> pins;
  final bool isTestEnvironment;
  final Widget bottomSheet;
  final VoidCallback onClose;
  final PinDto? selectedPin;
  final Function(Location)? onMapLongTapped;
  final Function(PinDto)? onMarkerTapped;
  final Function(PinDto)? onMarkerUpdated;
  final Function(String)? onMarkerDeleted;
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
      onMarkerTapped: onMarkerTapped,
      onMarkerUpdated: onMarkerUpdated,
      onMarkerDeleted: onMarkerDeleted,
      selectedPin: selectedPin,
    );
  }
}
