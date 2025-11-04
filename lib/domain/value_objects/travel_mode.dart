enum TravelMode { drive, walk /*, transit*/ }

extension TravelModeExtension on TravelMode {
  String get apiValue {
    switch (this) {
      case TravelMode.drive:
        return 'DRIVE';
      case TravelMode.walk:
        return 'WALK';
      // case TravelMode.transit:
      //   return 'TRANSIT';
    }
  }

  String get label {
    switch (this) {
      case TravelMode.drive:
        return '自動車';
      case TravelMode.walk:
        return '徒歩';
      // case TravelMode.transit:
      //   return '公共交通機関';
    }
  }
}
