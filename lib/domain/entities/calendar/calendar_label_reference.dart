bool validCalendarLabelReference(
  String type,
  String memberId,
  String labelId,
) => switch (type) {
  'group' => memberId.isEmpty && labelId.isEmpty,
  'member' => memberId.trim().isNotEmpty && labelId.isEmpty,
  'custom' => memberId.isEmpty && labelId.trim().isNotEmpty,
  _ => false,
};
