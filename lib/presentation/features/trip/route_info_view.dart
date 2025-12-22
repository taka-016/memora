import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/usecases/trip/fetch_route_info_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/constants/color_constants.dart';
import 'package:memora/domain/value_objects/route_segment_detail.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/presentation/shared/sheets/route_memo_edit_bottom_sheet.dart';

part 'route_list.dart';
part 'route_map.dart';

const double _inactivePolylineOpacity = 0.4;

String _routeSegmentKey(PinDto origin, PinDto destination) {
  return '${origin.pinId}->${destination.pinId}';
}

bool _hasManualContent(RouteSegmentDetail detail) {
  return detail.instructions.isNotEmpty || detail.durationSeconds > 0;
}

class RouteInfoViewTestHandle {
  Map<String, RouteSegmentDetail> Function()? _getSegmentDetails;
  int? Function()? _getSelectedPinIndex;
  Map<String, Color> Function()? _getSegmentHighlightColors;
  bool Function()? _getShouldFitMap;
  void Function(int index)? _selectPin;

  Map<String, RouteSegmentDetail> get segmentDetails =>
      _getSegmentDetails?.call() ?? const {};

  int? get selectedPinIndex => _getSelectedPinIndex?.call();

  Map<String, Color> get segmentHighlightColors =>
      _getSegmentHighlightColors?.call() ?? const {};

  bool get shouldFitMapToRoutesWhenVisible => _getShouldFitMap?.call() ?? false;

  void selectPinForTest(int index) {
    _selectPin?.call(index);
  }
}

class RouteInfoView extends HookConsumerWidget {
  const RouteInfoView({
    super.key,
    required this.pins,
    this.fetchRouteInfoUsecase,
    this.onClose,
    this.isTestEnvironment = false,
    this.testHandle,
  });

  final List<PinDto> pins;
  final FetchRouteInfoUsecase? fetchRouteInfoUsecase;
  final VoidCallback? onClose;
  final bool isTestEnvironment;
  final RouteInfoViewTestHandle? testHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FetchRouteInfoUsecase usecase =
        fetchRouteInfoUsecase ?? ref.read(fetchRouteInfoUsecaseProvider);

    final pinsState = useState<List<PinDto>>(List<PinDto>.from(pins));
    final segmentModesState = useState<Map<String, TravelMode>>({});
    final segmentDetailsState = useState<Map<String, RouteSegmentDetail>>({});
    final routeMemoExpansionState = useState<Map<String, bool>>({});
    final isLoadingState = useState(false);
    final errorMessageState = useState<String?>(null);
    final isMapVisibleState = useState(true);
    final selectedPinIndexState = useState<int?>(null);
    final mapControllerState = useState<GoogleMapController?>(null);
    final shouldFitMapState = useState(false);

    Future<void> searchRoutes() async {
      if (pinsState.value.length < 2) {
        return;
      }

      isLoadingState.value = true;
      errorMessageState.value = null;

      final nextResults = <String, RouteSegmentDetail>{};

      try {
        nextResults.addAll(
          await usecase.execute(
            pins: pinsState.value,
            segmentModes: segmentModesState.value,
            existingDetails: segmentDetailsState.value,
          ),
        );

        if (!context.mounted) {
          return;
        }
        segmentDetailsState.value = nextResults;
        routeMemoExpansionState.value = {
          for (final entry in nextResults.entries) entry.key: false,
        };
        shouldFitMapState.value = true;
      } catch (e, stackTrace) {
        logger.e(
          'RouteInfoView.searchRoutes: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        );
        if (!context.mounted) {
          return;
        }
        errorMessageState.value = '経路の取得に失敗しました: $e';
      } finally {
        if (context.mounted) {
          isLoadingState.value = false;
        }
      }
    }

    void handleClose() {
      if (onClose != null) {
        onClose!();
        return;
      }
      Navigator.of(context).maybePop();
    }

    Widget buildHeader() {
      return Row(
        children: [
          const Text(
            '経路情報',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(onPressed: handleClose, icon: const Icon(Icons.close)),
        ],
      );
    }

    Widget buildActionRow() {
      return Row(
        children: [
          ElevatedButton(
            onPressed: isLoadingState.value ? null : searchRoutes,
            child: isLoadingState.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('経路検索'),
          ),
        ],
      );
    }

    Widget buildErrorBanner() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          errorMessageState.value!,
          style: TextStyle(color: Colors.red.shade700, fontSize: 14),
        ),
      );
    }

    useEffect(() {
      return () {
        mapControllerState.value?.dispose();
      };
    }, []);

    useEffect(() {
      if (testHandle == null) {
        return null;
      }
      final handle = testHandle!;
      handle._getSegmentDetails = () =>
          Map<String, RouteSegmentDetail>.unmodifiable(
            segmentDetailsState.value,
          );
      handle._getSelectedPinIndex = () => selectedPinIndexState.value;
      handle._getSegmentHighlightColors = () => _computeSegmentHighlightColors(
        segmentDetails: segmentDetailsState.value,
        pins: pinsState.value,
        selectedPinIndex: selectedPinIndexState.value,
      );
      handle._getShouldFitMap = () => shouldFitMapState.value;
      handle._selectPin = (index) {
        if (index < 0 || index >= pinsState.value.length) {
          return;
        }
        selectedPinIndexState.value = index;
      };
      return () {
        if (testHandle == null) {
          return;
        }
        handle
          .._getSegmentDetails = null
          .._getSelectedPinIndex = null
          .._getSegmentHighlightColors = null
          .._getShouldFitMap = null
          .._selectPin = null;
      };
    }, [testHandle]);

    return SizedBox(
      key: const Key('route_info_view_root'),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(),
          const SizedBox(height: 16),
          buildActionRow(),
          if (errorMessageState.value != null) ...[
            const SizedBox(height: 12),
            buildErrorBanner(),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: RouteList(
                    pinsState: pinsState,
                    segmentModesState: segmentModesState,
                    segmentDetailsState: segmentDetailsState,
                    routeMemoExpansionState: routeMemoExpansionState,
                    selectedPinIndexState: selectedPinIndexState,
                  ),
                ),
                RouteMap(
                  pinsState: pinsState,
                  segmentDetailsState: segmentDetailsState,
                  selectedPinIndexState: selectedPinIndexState,
                  isMapVisibleState: isMapVisibleState,
                  mapControllerState: mapControllerState,
                  shouldFitMapState: shouldFitMapState,
                  isTestEnvironment: isTestEnvironment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
