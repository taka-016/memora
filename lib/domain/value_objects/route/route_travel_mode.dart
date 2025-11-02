enum RouteTravelMode { drive, walk, transit }

extension RouteTravelModeApiValue on RouteTravelMode {
  String? get apiValue {
    switch (this) {
      case RouteTravelMode.drive:
        return 'DRIVE';
      case RouteTravelMode.walk:
        return 'WALK';
      case RouteTravelMode.transit:
        return 'TRANSIT';
    }
  }

  String get label {
    switch (this) {
      case RouteTravelMode.drive:
        return '自動車';
      case RouteTravelMode.walk:
        return '徒歩';
      case RouteTravelMode.transit:
        return '公共交通機関';
    }
  }
}
