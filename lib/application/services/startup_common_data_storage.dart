import 'package:memora/application/models/startup_common_data.dart';

abstract class StartupCommonDataStorage {
  Future<StartupCommonData?> load(String owner);
  Future<void> save(String owner, StartupCommonData data);
}
