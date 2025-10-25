import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/usecases/trip/get_pins_by_member_id_usecase.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';

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
  late final GetPinsByMemberIdUsecase _getPinsByMemberIdUsecase;

  List<PinDto> _pins = [];

  @override
  void initState() {
    super.initState();

    _getPinsByMemberIdUsecase = ref.read(getPinsByMemberIdUsecaseProvider);

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
