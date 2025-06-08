import '../entities/location_candidate.dart';

abstract class LocationSearchService {
  Future<List<LocationCandidate>> searchByKeyword(String keyword);
}
