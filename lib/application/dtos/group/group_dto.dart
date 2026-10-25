import 'package:memora/application/dtos/copy_with_helper.dart';
import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';

class GroupDto extends Equatable {
  const GroupDto({
    this.version,
    required this.id,
    required this.ownerId,
    required this.name,
    this.memo,
    this.color = '#4CAF50',
    this.textColor,
    required this.members,
    this.originalMembers,
  });

  final int? version;
  final String id;
  final String ownerId;
  final String color;
  final String? textColor;
  final String name;
  final String? memo;
  final List<GroupMemberDto> members;
  // 編集開始時の通常メンバーから、所属の明示的な除外を判定する。
  final List<GroupMemberDto>? originalMembers;

  GroupDto copyWith({
    int? version,
    String? color,
    Object? textColor = copyWithPlaceholder,
    String? id,
    String? ownerId,
    String? name,
    String? memo,
    List<GroupMemberDto>? members,
    List<GroupMemberDto>? originalMembers,
  }) {
    return GroupDto(
      version: version ?? this.version,
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      color: color ?? this.color,
      textColor: resolveCopyWithValue<String>(
        textColor,
        this.textColor,
        'textColor',
      ),
      name: name ?? this.name,
      memo: memo ?? this.memo,
      members: members ?? this.members,
      originalMembers: originalMembers ?? this.originalMembers ?? this.members,
    );
  }

  @override
  List<Object?> get props => [
    color,
    textColor,
    version,
    id,
    ownerId,
    name,
    memo,
    members,
    originalMembers,
  ];
}
