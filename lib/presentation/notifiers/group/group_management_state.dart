import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/group/group_dto.dart';

class GroupManagementState extends Equatable {
  const GroupManagementState({this.groups = const []});

  final List<GroupDto> groups;

  @override
  List<Object?> get props => [groups];
}
