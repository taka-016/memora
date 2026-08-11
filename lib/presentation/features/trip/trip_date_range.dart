abstract final class TripDateRange {
  static const firstYear = 2000;
  static const lastYear = 2100;

  static bool containsYear(int? year) {
    return year != null && year >= firstYear && year <= lastYear;
  }
}
