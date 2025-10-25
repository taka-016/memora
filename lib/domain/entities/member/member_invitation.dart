import 'package:equatable/equatable.dart';

class MemberInvitation extends Equatable {
  const MemberInvitation({
    required this.id,
    required this.inviteeId,
    required this.inviterId,
    required this.invitationCode,
  });

  final String id;
  final String inviteeId;
  final String inviterId;
  final String invitationCode;

  MemberInvitation copyWith({
    String? id,
    String? inviteeId,
    String? inviterId,
    String? invitationCode,
  }) {
    return MemberInvitation(
      id: id ?? this.id,
      inviteeId: inviteeId ?? this.inviteeId,
      inviterId: inviterId ?? this.inviterId,
      invitationCode: invitationCode ?? this.invitationCode,
    );
  }

  @override
  List<Object?> get props => [id, inviteeId, inviterId, invitationCode];
}
