abstract class CalendarDefaultDurationStorage {
  Future<int> load();
  Future<void> save(int minutes);
}
