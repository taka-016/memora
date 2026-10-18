import 'package:equatable/equatable.dart';

class MemberInvitation extends Equatable {
  const MemberInvitation({
    this.version,
    required this.id,
    required this.inviteeId,
    required this.inviterId,
    required this.invitationCode,
  });

  final int? version;
  final String id;
  final String inviteeId;
  final String inviterId;
  final String invitationCode;

  MemberInvitation copyWith({
    int? version,
    String? id,
    String? inviteeId,
    String? inviterId,
    String? invitationCode,
  }) {
    return MemberInvitation(
      version: version ?? this.version,
      id: id ?? this.id,
      inviteeId: inviteeId ?? this.inviteeId,
      inviterId: inviterId ?? this.inviterId,
      invitationCode: invitationCode ?? this.invitationCode,
    );
  }

  @override
  List<Object?> get props => [
    version,
    id,
    inviteeId,
    inviterId,
    invitationCode,
  ];
}
