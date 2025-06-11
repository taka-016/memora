class TripEntry {
  final String id;
  final String pinId;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final String tripMemo;

  TripEntry({
    required this.id,
    required this.pinId,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.tripMemo,
  });
}
