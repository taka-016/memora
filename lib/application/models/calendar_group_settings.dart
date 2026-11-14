class CalendarGroupSettings {
  CalendarGroupSettings({
    Set<String> visibleGroupIds = const {},
    this.defaultGroupId,
  }) : visibleGroupIds = Set.unmodifiable(visibleGroupIds);

  final Set<String> visibleGroupIds;
  final String? defaultGroupId;

  CalendarGroupSettings retainGroups(Set<String> ids) => CalendarGroupSettings(
    visibleGroupIds: visibleGroupIds.intersection(ids),
    defaultGroupId: ids.contains(defaultGroupId) ? defaultGroupId : null,
  );
}
