class Pin {
  final String id;
  final String pinId;
  final String? tripId;
  final double latitude;
  final double longitude;
  final DateTime? visitStartDate;
  final DateTime? visitEndDate;
  final String? visitMemo;

  Pin({
    required this.id,
    required this.pinId,
    this.tripId,
    required this.latitude,
    required this.longitude,
    this.visitStartDate,
    this.visitEndDate,
    this.visitMemo,
  });
}
