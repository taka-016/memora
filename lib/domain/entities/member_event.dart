class MemberEvent {
  final String id;
  final String memberId;
  final String type;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String memo;

  MemberEvent({
    required this.id,
    required this.memberId,
    required this.type,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.memo,
  });
}
