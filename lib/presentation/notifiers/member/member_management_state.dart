import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/member/member_dto.dart';

class MemberManagementState extends Equatable {
  const MemberManagementState({this.members = const []});

  final List<MemberDto> members;

  @override
  List<Object?> get props => [members];
}
