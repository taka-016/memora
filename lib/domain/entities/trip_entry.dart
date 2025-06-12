class TripEntry {
  final String id;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final String pinId;
  final String tripMemo;

  TripEntry({
    required this.id,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.pinId,
    required this.tripMemo,
  });
}
