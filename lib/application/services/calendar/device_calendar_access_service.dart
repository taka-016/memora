abstract class DeviceCalendarAccessService {
  Future<bool> hasReadPermission();
  Future<bool> requestReadPermission();
}
