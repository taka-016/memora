enum AndroidWidgetUpdateInterval {
  every1Minute(minutes: 1, label: '1分（検証用）'),
  every5Minutes(minutes: 5, label: '5分（検証用）'),
  every1Hour(minutes: 60, label: '1時間'),
  every3Hours(minutes: 180, label: '3時間'),
  every6Hours(minutes: 360, label: '6時間'),
  every12Hours(minutes: 720, label: '12時間'),
  every24Hours(minutes: 1440, label: '24時間');

  const AndroidWidgetUpdateInterval({
    required this.minutes,
    required this.label,
  });

  final int minutes;
  final String label;

  Duration get duration => Duration(minutes: minutes);
}
