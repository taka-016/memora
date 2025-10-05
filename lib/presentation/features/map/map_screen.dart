import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/application/interfaces/pin_query_service.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/infrastructure/services/firestore_pin_query_service.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';
import 'package:memora/presentation/shared/sheets/pin_detail_bottom_sheet.dart';

final pinQueryServiceProvider = Provider<PinQueryService>((ref) {
  return FirestorePinQueryService(firestore: FirebaseFirestore.instance);
});

class MapScreen extends ConsumerStatefulWidget {
  final bool isTestEnvironment;

  const MapScreen({super.key, this.isTestEnvironment = false});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  List<PinDto> _pins = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPins();
    });
  }

  Future<void> _loadPins() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) {
      return;
    }

    final pinQueryService = ref.read(pinQueryServiceProvider);
    final pins = await pinQueryService.getPinsByMemberId(authState.user!.id);
    if (mounted) {
      setState(() {
        _pins = pins;
      });
    }
  }

  void _onMapLongTapped(Location location) {
    // WIP
  }

  void _onMarkerTapped(PinDto pin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PinDetailBottomSheet(
        pin: pin,
        onClose: () => Navigator.pop(context),
        onUpdate: null,
        onDelete: null,
      ),
    );
  }

  void _onMarkerUpdated(PinDto pin) {
    // WIP
  }

  void _onMarkerDeleted(String pinId) {
    // WIP
  }

  @override
  Widget build(BuildContext context) {
    final mapViewType = widget.isTestEnvironment
        ? MapViewType.placeholder
        : MapViewType.google;

    return MapViewFactory.create(mapViewType).createMapView(
      pins: _pins,
      onMapLongTapped: _onMapLongTapped,
      onMarkerTapped: _onMarkerTapped,
      onMarkerUpdated: _onMarkerUpdated,
      onMarkerDeleted: _onMarkerDeleted,
    );
  }
}
