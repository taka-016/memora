class Pin {
  final String id;
  final double latitude;
  final double longitude;

  Pin({required this.id, required this.latitude, required this.longitude});

  factory Pin.fromFirestore(String id, Map<String, dynamic> data) {
    return Pin(
      id: id,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
    );
  }
}
