class CalendarEventMutationResult {
  CalendarEventMutationResult({
    this.savedId,
    required Set<String> affectedGroupIds,
  }) : affectedGroupIds = Set.unmodifiable(affectedGroupIds);

  final String? savedId;
  final Set<String> affectedGroupIds;
}
