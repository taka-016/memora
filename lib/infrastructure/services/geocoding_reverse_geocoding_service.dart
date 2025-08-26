import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:memora/domain/services/reverse_geocoding_service.dart';
import 'package:memora/domain/value-objects/location.dart' as domain;

class GeocodingReverseGeocodingService implements ReverseGeocodingService {
  const GeocodingReverseGeocodingService();

  @override
  Future<String?> getLocationName(domain.Location location) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        return null;
      }

      final placemark = placemarks.first;

      // 施設名を最優先で表示
      if (placemark.name != null && placemark.name!.isNotEmpty) {
        return placemark.name;
      }

      // 施設名がない場合は住所を表示
      final addressParts = <String>[];

      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        addressParts.add(placemark.locality!);
      }
      if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
        addressParts.add(placemark.subLocality!);
      }
      if (placemark.thoroughfare != null &&
          placemark.thoroughfare!.isNotEmpty) {
        addressParts.add(placemark.thoroughfare!);
      }
      if (placemark.subThoroughfare != null &&
          placemark.subThoroughfare!.isNotEmpty) {
        addressParts.add(placemark.subThoroughfare!);
      }

      return addressParts.isEmpty ? null : addressParts.join(' ');
    } catch (e) {
      return null;
    }
  }
}
