import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/services/shared_calendar_cache.dart';

final sharedCalendarCacheProvider = Provider<SharedCalendarCache>(
  (ref) => SharedCalendarCache(),
);

final onlineCalendarCacheOwnerProvider = Provider<String? Function()>((ref) {
  return () {
    if (!ref.mounted) return null;
    final id = ref.read(firebaseAuthProvider).currentUser?.uid;
    return id == null ? null : 'online:$id';
  };
});
