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

      // 施設名やPOI（Point of Interest）を優先的に表示
      // nameが数字のみの場合（番地など）は施設名とみなさない
      if (placemark.name != null && placemark.name!.isNotEmpty) {
        final isNumeric = _isNumericString(placemark.name!);
        if (!isNumeric) {
          return placemark.name;
        }
      }

      // 住所情報から適切な表示名を構築
      // より細かい地域名を最優先（町丁目レベル - 例：舞浜）
      if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
        return placemark.subLocality!; // 町丁目名があればそれだけを返す
      }

      // 地域名（市区町村レベル - 例：浦安市）
      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        return placemark.locality!; // 市区町村名があればそれだけを返す
      }

      // 道路名
      if (placemark.thoroughfare != null &&
          placemark.thoroughfare!.isNotEmpty) {
        return placemark.thoroughfare!;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  bool _isNumericString(String str) {
    final trimmed = str.trim();

    // 空文字列の場合はfalse
    if (trimmed.isEmpty) {
      return false;
    }

    // 数字、各種ハイフン類、スペース類のみで構成されている場合は番地とみなす
    // 使用可能文字: 半角数字、全角数字、各種ハイフン（\u002D, \u2212, \u30FC, \uFF0D）、スペース類
    final hasOnlyAddressChars = RegExp(
      r'^[0-9０-９\-\u002D\u2212\u30FC\uFF0D\s　]+$',
    ).hasMatch(trimmed);
    final hasAtLeastOneDigit = RegExp(r'[0-9０-９]').hasMatch(trimmed);

    final result = hasOnlyAddressChars && hasAtLeastOneDigit;

    return result;
  }
}
