import 'package:memora/application/models/app_capabilities.dart';

class FeatureUnavailableException implements Exception {
  const FeatureUnavailableException(this.feature, this.reason);

  final AppFeature feature;
  final String reason;

  @override
  String toString() => 'FeatureUnavailableException: $reason';
}
