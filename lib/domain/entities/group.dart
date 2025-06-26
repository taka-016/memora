class Group {
  final String id;
  final String administratorId;
  final String name;
  final String? memo;

  Group({
    required this.id,
    required this.administratorId,
    required this.name,
    this.memo,
  });
}
