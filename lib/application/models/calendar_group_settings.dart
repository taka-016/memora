class CalendarGroupSettings {
  CalendarGroupSettings({
    Set<String> visibleGroupIds = const {},
    this.defaultGroupId,
    this.hasSavedSettings = true,
  }) : visibleGroupIds = Set.unmodifiable(visibleGroupIds);

  final Set<String> visibleGroupIds;
  final String? defaultGroupId;
  final bool hasSavedSettings;

  CalendarGroupSettings retainGroups(Set<String> ids) => CalendarGroupSettings(
    visibleGroupIds: visibleGroupIds.intersection(ids),
    hasSavedSettings: hasSavedSettings,
    defaultGroupId: ids.contains(defaultGroupId) ? defaultGroupId : null,
  );
}
