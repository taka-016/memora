import 'package:equatable/equatable.dart';

class MemberInvitationDto extends Equatable {
  const MemberInvitationDto({
    this.version,
    required this.id,
    required this.inviteeId,
    required this.inviterId,
    required this.invitationCode,
    this.createdAt,
    this.updatedAt,
  });

  final int? version;
  final String id;
  final String inviteeId;
  final String inviterId;
  final String invitationCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MemberInvitationDto copyWith({
    int? version,
    String? id,
    String? inviteeId,
    String? inviterId,
    String? invitationCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberInvitationDto(
      version: version ?? this.version,
      id: id ?? this.id,
      inviteeId: inviteeId ?? this.inviteeId,
      inviterId: inviterId ?? this.inviterId,
      invitationCode: invitationCode ?? this.invitationCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    version,
    id,
    inviteeId,
    inviterId,
    invitationCode,
    createdAt,
    updatedAt,
  ];
}
