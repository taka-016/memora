import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/usecases/trip/get_pins_by_member_id_usecase.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';

class MapScreen extends HookConsumerWidget {
  final MemberDto member;
  final bool isTestEnvironment;

  const MapScreen({
    super.key,
    required this.member,
    this.isTestEnvironment = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getPinsByMemberIdUsecase = useMemoized(
      () => ref.read(getPinsByMemberIdUsecaseProvider),
    );
    final pins = useState<List<PinDto>>([]);

    useEffect(() {
      Future.microtask(() async {
        pins.value = await getPinsByMemberIdUsecase.execute(member.id);
      });
      return null;
    }, [getPinsByMemberIdUsecase, member.id]);

    final mapViewType = isTestEnvironment
        ? MapViewType.placeholder
        : MapViewType.google;

    return MapViewFactory.create(
      mapViewType,
    ).createMapView(pins: pins.value, isReadOnly: true);
  }
}
