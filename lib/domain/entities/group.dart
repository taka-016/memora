import 'package:equatable/equatable.dart';
import 'package:memora/domain/entities/group_member.dart';

class Group extends Equatable {
  const Group({
    required this.id,
    required this.ownerId,
    required this.name,
    this.memo,
    this.members = const [],
  });

  final String id;
  final String ownerId;
  final String name;
  final String? memo;
  final List<GroupMember>? members;

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

  @override
  List<Object?> get props => [id, ownerId, name, memo, members];
}
