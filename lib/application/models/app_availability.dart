enum AppAvailability { available, updateRequired, maintenance }

class AppAvailabilitySettings {
  const AppAvailabilitySettings({
    required this.minimumBuildNumber,
    required this.isMaintenance,
  });

  final int minimumBuildNumber;
  final bool isMaintenance;
}
