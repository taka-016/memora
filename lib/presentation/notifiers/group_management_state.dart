import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';

enum GroupManagementOperationStatus { idle, loading, success, error }

enum GroupManagementOperationType {
  loadAvailableMembers,
  create,
  update,
  delete,
}

class GroupManagementState extends Equatable {
  const GroupManagementState({
    this.operationStatus = GroupManagementOperationStatus.idle,
    this.operationType,
    this.groups = const [],
    this.availableMembers = const [],
    this.errorMessage = '',
  });

  final GroupManagementOperationStatus operationStatus;
  final GroupManagementOperationType? operationType;
  final List<GroupDto> groups;
  final List<GroupMemberDto> availableMembers;
  final String errorMessage;

  GroupManagementState copyWith({
    GroupManagementOperationStatus? operationStatus,
    GroupManagementOperationType? operationType,
    bool clearOperationType = false,
    List<GroupDto>? groups,
    List<GroupMemberDto>? availableMembers,
    String? errorMessage,
  }) {
    return GroupManagementState(
      operationStatus: operationStatus ?? this.operationStatus,
      operationType: clearOperationType
          ? null
          : operationType ?? this.operationType,
      groups: groups ?? this.groups,
      availableMembers: availableMembers ?? this.availableMembers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    operationStatus,
    operationType,
    groups,
    availableMembers,
    errorMessage,
  ];
}
