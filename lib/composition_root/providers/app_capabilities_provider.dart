import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';

final appCapabilitiesProvider = Provider<AppCapabilities>((ref) {
  return AppCapabilities.forMode(ref.watch(appModeProvider));
});
