abstract interface class CalendarGroupInitializationPolicy {
  Future<bool> canInitialize(String ownerId);
  Future<void> markRestored(String ownerId);
}
