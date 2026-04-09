enum GroupTimelineRowType {
  trip,
  groupEvent,
  dvc,
  member;

  static GroupTimelineRowType? fromName(String? name) {
    if (name == null) {
      return null;
    }
    for (final value in GroupTimelineRowType.values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }
}
