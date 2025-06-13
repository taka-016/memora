class GroupEvent {
  final String id;
  final String groupId;
  final String type;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String memo;

  GroupEvent({
    required this.id,
    required this.groupId,
    required this.type,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.memo,
  });
}
