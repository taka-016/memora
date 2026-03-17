import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/config/location_search_api_type.dart';

final locationSearchApiTypeProvider = StateProvider<LocationSearchApiType>(
  (ref) => LocationSearchApiType.googlePlaces,
);
