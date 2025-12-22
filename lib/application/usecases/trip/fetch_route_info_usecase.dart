import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/domain/services/route_info_service.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/route_segment_detail.dart';
import 'package:memora/infrastructure/factories/route_info_service_factory.dart';

final fetchRouteInfoUsecaseProvider = Provider<FetchRouteInfoUsecase>((ref) {
  return FetchRouteInfoUsecase(ref.watch(routeInfoServiceProvider));
});

class FetchRouteInfoUsecase {
  final RouteInfoService _routeInfoService;

  FetchRouteInfoUsecase(this._routeInfoService);

  Future<Map<String, RouteSegmentDetail>> execute({
    required List<PinDto> pins,
    required Map<String, TravelMode> segmentModes,
    required Map<String, RouteSegmentDetail> existingDetails,
  }) async {
    if (pins.length < 2) {
      return {};
    }

    final results = <String, RouteSegmentDetail>{};
    for (var i = 0; i < pins.length - 1; i++) {
      final origin = pins[i];
      final destination = pins[i + 1];
      final key = _segmentKey(origin, destination);
      final mode = segmentModes[key] ?? TravelMode.drive;

      var detail = await _routeInfoService.fetchRoute(
        origin: Location(
          latitude: origin.latitude,
          longitude: origin.longitude,
        ),
        destination: Location(
          latitude: destination.latitude,
          longitude: destination.longitude,
        ),
        travelMode: mode,
      );

      detail = _mergeManualDetailIfNeeded(
        key: key,
        mode: mode,
        fetchedDetail: detail,
        existingDetails: existingDetails,
      );
      results[key] = detail;
    }

    return results;
  }

  RouteSegmentDetail _mergeManualDetailIfNeeded({
    required String key,
    required TravelMode mode,
    required RouteSegmentDetail fetchedDetail,
    required Map<String, RouteSegmentDetail> existingDetails,
  }) {
    if (mode != TravelMode.other) {
      return fetchedDetail;
    }

    final existingDetail = existingDetails[key];
    if (existingDetail == null || !_hasManualContent(existingDetail)) {
      return fetchedDetail;
    }

    final updatedPolyline = fetchedDetail.polyline.isNotEmpty
        ? fetchedDetail.polyline
        : existingDetail.polyline;
    return existingDetail.copyWith(polyline: updatedPolyline);
  }
}

String _segmentKey(PinDto origin, PinDto destination) {
  return '${origin.pinId}->${destination.pinId}';
}

bool _hasManualContent(RouteSegmentDetail detail) {
  return detail.instructions.isNotEmpty || detail.durationSeconds > 0;
}
