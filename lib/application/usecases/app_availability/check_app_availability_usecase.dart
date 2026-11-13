import 'package:memora/application/models/app_availability.dart';
import 'package:memora/application/services/app_availability_source.dart';

class CheckAppAvailabilityUsecase {
  const CheckAppAvailabilityUsecase({
    required this._source,
    required this._loadBuildNumber,
  });

  const CheckAppAvailabilityUsecase.unrestricted()
    : _source = null,
      _loadBuildNumber = null;

  final AppAvailabilitySource? _source;
  final Future<int> Function()? _loadBuildNumber;

  Future<AppAvailability> execute() async {
    final source = _source;
    if (source == null) return AppAvailability.available;
    final settings = await source.load();
    if (settings.isMaintenance) return AppAvailability.maintenance;
    final buildNumber = await _loadBuildNumber!();
    return buildNumber < settings.minimumBuildNumber
        ? AppAvailability.updateRequired
        : AppAvailability.available;
  }

  Future<bool> runIfAvailable(Future<void> Function() action) async {
    if (await execute() != AppAvailability.available) return false;
    await action();
    return true;
  }
}
