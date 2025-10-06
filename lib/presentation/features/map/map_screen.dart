import 'package:flutter/material.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/application/interfaces/pin_query_service.dart';
import 'package:memora/application/usecases/pin/get_pins_by_member_id_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/infrastructure/services/firestore_pin_query_service.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';

class MapScreen extends StatefulWidget {
  final Member member;
  final bool isTestEnvironment;
  final PinQueryService? pinQueryService;

  const MapScreen({
    super.key,
    required this.member,
    this.isTestEnvironment = false,
    this.pinQueryService,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final GetPinsByMemberIdUsecase _getPinsByMemberIdUsecase;

  List<PinDto> _pins = [];

  @override
  void initState() {
    super.initState();

    final pinQueryService =
        widget.pinQueryService ?? FirestorePinQueryService();

    _getPinsByMemberIdUsecase = GetPinsByMemberIdUsecase(pinQueryService);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPins();
    });
  }

  Future<void> _loadPins() async {
    final pins = await _getPinsByMemberIdUsecase.execute(widget.member.id);
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
