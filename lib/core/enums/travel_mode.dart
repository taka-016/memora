enum TravelMode { drive, walk, other }

extension TravelModeExtension on TravelMode {
  String get apiValue {
    switch (this) {
      case TravelMode.drive:
        return 'DRIVE';
      case TravelMode.walk:
        return 'WALK';
      case TravelMode.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case TravelMode.drive:
        return '自動車';
      case TravelMode.walk:
        return '徒歩';
      case TravelMode.other:
        return 'その他';
    }
  }
}
