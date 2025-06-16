class TripEntry {
  final String id;
  final String? tripName;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final String? tripMemo;

  TripEntry({
    required this.id,
    this.tripName,
    required this.tripStartDate,
    required this.tripEndDate,
    this.tripMemo,
  });
}
