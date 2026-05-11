import 'package:equatable/equatable.dart';

class MemberInvitationDto extends Equatable {
  const MemberInvitationDto({
    required this.id,
    required this.inviteeId,
    required this.inviterId,
    required this.invitationCode,
    this.createdAt,
  });

  final String id;
  final String inviteeId;
  final String inviterId;
  final String invitationCode;
  final DateTime? createdAt;

  MemberInvitationDto copyWith({
    String? id,
    String? inviteeId,
    String? inviterId,
    String? invitationCode,
    DateTime? createdAt,
  }) {
    return MemberInvitationDto(
      id: id ?? this.id,
      inviteeId: inviteeId ?? this.inviteeId,
      inviterId: inviterId ?? this.inviterId,
      invitationCode: invitationCode ?? this.invitationCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    inviteeId,
    inviterId,
    invitationCode,
    createdAt,
  ];
}
