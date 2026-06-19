enum AndroidWidgetUpdateInterval {
  every1Hour(hours: 1, label: '1時間'),
  every3Hours(hours: 3, label: '3時間'),
  every6Hours(hours: 6, label: '6時間'),
  every12Hours(hours: 12, label: '12時間'),
  every24Hours(hours: 24, label: '24時間');

  const AndroidWidgetUpdateInterval({required this.hours, required this.label});

  final int hours;
  final String label;

  Duration get duration => Duration(hours: hours);
}
