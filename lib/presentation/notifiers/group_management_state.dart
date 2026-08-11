import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';

enum GroupManagementStatus { initial, loading, loaded, error }

enum GroupManagementRefreshStatus { idle, loading, error }

enum GroupManagementOperationStatus { idle, loading, success, error }

enum GroupManagementOperationType {
  loadAvailableMembers,
  create,
  update,
  delete,
}

class GroupManagementState extends Equatable {
  const GroupManagementState({
    this.status = GroupManagementStatus.initial,
    this.refreshStatus = GroupManagementRefreshStatus.idle,
    this.operationStatus = GroupManagementOperationStatus.idle,
    this.operationType,
    this.groups = const [],
    this.availableMembers = const [],
    this.errorMessage = '',
  });

  final GroupManagementStatus status;
  final GroupManagementRefreshStatus refreshStatus;
  final GroupManagementOperationStatus operationStatus;
  final GroupManagementOperationType? operationType;
  final List<GroupDto> groups;
  final List<GroupMemberDto> availableMembers;
  final String errorMessage;

  GroupManagementState copyWith({
    GroupManagementStatus? status,
    GroupManagementRefreshStatus? refreshStatus,
    GroupManagementOperationStatus? operationStatus,
    GroupManagementOperationType? operationType,
    bool clearOperationType = false,
    List<GroupDto>? groups,
    List<GroupMemberDto>? availableMembers,
    String? errorMessage,
  }) {
    return GroupManagementState(
      status: status ?? this.status,
      refreshStatus: refreshStatus ?? this.refreshStatus,
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
    status,
    refreshStatus,
    operationStatus,
    operationType,
    groups,
    availableMembers,
    errorMessage,
  ];
}
