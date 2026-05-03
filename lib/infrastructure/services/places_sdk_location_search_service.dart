import 'package:flutter/services.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/core/models/coordinate.dart';

class PlacesSdkLocationSearchService implements LocationSearchService {
  PlacesSdkLocationSearchService({
    MethodChannel channel = const MethodChannel('memora/places'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<List<LocationCandidateDto>> searchByKeyword(String keyword) async {
    final places = await _channel.invokeMethod<List<dynamic>>('searchByText', {
      'query': keyword,
    });

    return (places ?? const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map(_toLocationCandidate)
        .toList();
  }

  LocationCandidateDto _toLocationCandidate(Map<dynamic, dynamic> place) {
    return LocationCandidateDto(
      name: place['name'] as String? ?? '',
      address: place['address'] as String? ?? '',
      coordinate: Coordinate(
        latitude: (place['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (place['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
    );
  }
}
