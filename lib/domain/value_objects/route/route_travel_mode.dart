enum RouteTravelMode { unspecified, drive, walk, transit, twoWheeler, bicycle }

extension RouteTravelModeApiValue on RouteTravelMode {
  String? get apiValue {
    switch (this) {
      case RouteTravelMode.unspecified:
        return null;
      case RouteTravelMode.drive:
        return 'DRIVE';
      case RouteTravelMode.walk:
        return 'WALK';
      case RouteTravelMode.transit:
        return 'TRANSIT';
      case RouteTravelMode.twoWheeler:
        return 'TWO_WHEELER';
      case RouteTravelMode.bicycle:
        return 'BICYCLE';
    }
  }

  String get label {
    switch (this) {
      case RouteTravelMode.unspecified:
        return '未選択';
      case RouteTravelMode.drive:
        return '自動車';
      case RouteTravelMode.walk:
        return '徒歩';
      case RouteTravelMode.transit:
        return '公共交通機関';
      case RouteTravelMode.twoWheeler:
        return 'バイク';
      case RouteTravelMode.bicycle:
        return '自転車';
    }
  }
}
