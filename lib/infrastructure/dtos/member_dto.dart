class MemberDto {
  final String id;
  final String displayName;
  final String? email;

  MemberDto({required this.id, required this.displayName, this.email});

  factory MemberDto.fromFirestore(Map<String, dynamic> data, String id) {
    return MemberDto(
      id: id,
      displayName: data['displayName'] as String,
      email: data['email'] as String?,
    );
  }
}
