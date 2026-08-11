abstract final class SupportedYearRange {
  static const firstYear = 2000;
  static const lastYear = 2100;

  static bool contains(int? year) {
    return year != null && year >= firstYear && year <= lastYear;
  }
}
