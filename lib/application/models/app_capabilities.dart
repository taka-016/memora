import 'package:memora/application/models/app_mode.dart';

enum AppFeature {
  authentication,
  localData,
  maps,
  locationSearch,
  currentLocation,
  sharing,
  invitations,
}

class FeatureAvailability {
  const FeatureAvailability.available() : reason = null;
  const FeatureAvailability.unavailable(String this.reason);

  final String? reason;
  bool get isAvailable => reason == null;
}

class AppCapabilities {
  const AppCapabilities._(this._mode);

  factory AppCapabilities.forMode(AppMode mode) => AppCapabilities._(mode);

  final AppMode _mode;

  FeatureAvailability availability(AppFeature feature) {
    if (_mode == AppMode.online) {
      return const FeatureAvailability.available();
    }
    if (feature == AppFeature.localData) {
      return const FeatureAvailability.unavailable('端末内データの保存機能は現在準備中です。');
    }
    return const FeatureAvailability.unavailable('この機能はオンラインモードで利用できます。');
  }
}
