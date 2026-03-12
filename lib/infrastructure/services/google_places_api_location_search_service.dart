import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/core/models/coordinate.dart';

class GooglePlacesApiLocationSearchService implements LocationSearchService {
  final String apiKey;
  final http.Client httpClient;

  GooglePlacesApiLocationSearchService({
    required this.apiKey,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  @override
  Future<List<LocationCandidateDto>> searchByKeyword(String keyword) async {
    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/textsearch/json',
      {'query': keyword, 'key': apiKey, 'language': 'ja'},
    );
    final response = await httpClient.get(url);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch places: ${response.statusCode} ${response.body}',
      );
    }
    final data = json.decode(utf8.decode(response.bodyBytes));
    final results = data['results'];
    if (results is! List) return const [];
    return results.map<LocationCandidateDto>((item) {
      return LocationCandidateDto(
        name: item['name'] ?? '',
        address: item['formatted_address'] ?? '',
        coordinate: Coordinate(
          latitude:
              (item['geometry']?['location']?['lat'] as num?)?.toDouble() ??
              0.0,
          longitude:
              (item['geometry']?['location']?['lng'] as num?)?.toDouble() ??
              0.0,
        ),
      );
    }).toList();
  }
}
