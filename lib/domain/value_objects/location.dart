import 'package:equatable/equatable.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class Location extends Equatable {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude}) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw ValidationException('緯度は-90から90までの有限値である必要があります');
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw ValidationException('経度は-180から180までの有限値である必要があります');
    }
  }

  @override
  List<Object> get props => [latitude, longitude];
}
