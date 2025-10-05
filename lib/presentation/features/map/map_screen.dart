import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/application/interfaces/pin_query_service.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/infrastructure/services/firestore_pin_query_service.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';

final pinQueryServiceProvider = Provider<PinQueryService>((ref) {
  return FirestorePinQueryService(firestore: FirebaseFirestore.instance);
});

class MapScreen extends ConsumerStatefulWidget {
  final Member member;
  final bool isTestEnvironment;

  const MapScreen({
    super.key,
    required this.member,
    this.isTestEnvironment = false,
  });

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
    final pinQueryService = ref.read(pinQueryServiceProvider);
    final pins = await pinQueryService.getPinsByMemberId(widget.member.id);
    if (mounted) {
      setState(() {
        _pins = pins;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapViewType = widget.isTestEnvironment
        ? MapViewType.placeholder
        : MapViewType.google;

    return MapViewFactory.create(
      mapViewType,
    ).createMapView(pins: _pins, isReadOnly: true);
  }
}
