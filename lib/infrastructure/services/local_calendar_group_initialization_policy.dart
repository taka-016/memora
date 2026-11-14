import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:memora/application/services/calendar_group_initialization_policy.dart';

class LocalCalendarGroupInitializationPolicy
    implements CalendarGroupInitializationPolicy {
  LocalCalendarGroupInitializationPolicy({
    Future<Directory> Function()? directory,
  }) : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;
  Future<File> _file(String ownerId) async => File(
    '${(await _directory()).path}/calendar_restore_history/${Uri.encodeComponent(ownerId)}',
  );
  @override
  Future<bool> canInitialize(String ownerId) async =>
      !await (await _file(ownerId)).exists();
  @override
  Future<void> markRestored(String ownerId) async {
    await (await _file(ownerId)).create(recursive: true);
  }
}
