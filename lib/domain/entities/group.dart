import 'package:equatable/equatable.dart';
import 'package:memora/domain/entities/group_member.dart';

class Group extends Equatable {
  Group({
    required this.id,
    required this.ownerId,
    required this.name,
    this.memo,
    List<GroupMember>? members,
  }) : members = List.unmodifiable(members ?? const []) {
    if (members != null) {
      final memberIds = <String>{};
      for (final member in members) {
        if (!memberIds.add(member.memberId)) {
          throw ArgumentError('メンバーIDが重複しています: ${member.memberId}');
        }
      }
    }
  }

  final String id;
  final String ownerId;
  final String name;
  final String? memo;
  final List<GroupMember> members;

  Group copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? memo,
    List<GroupMember>? members,
  }) {
    return Group(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      memo: memo ?? this.memo,
      members: members ?? this.members,
    );
  }

  Group addMember(GroupMember member) {
    final updatedMembers = List<GroupMember>.from(members)..add(member);
    return copyWith(members: updatedMembers);
  }

  Group updateMember(String memberId, GroupMember member) {
    final updatedMembers = members
        .map((m) => m.memberId == memberId ? member : m)
        .toList();
    return copyWith(members: updatedMembers);
  }

  Group removeMember(String memberId) {
    final updatedMembers = members
        .where((m) => m.memberId != memberId)
        .toList();
    return copyWith(members: updatedMembers);
  }

  @override
  List<Object?> get props => [id, ownerId, name, memo, members];
}
