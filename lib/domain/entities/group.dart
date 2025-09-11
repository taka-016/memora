import 'package:equatable/equatable.dart';
import 'package:memora/domain/entities/group_event.dart';
import 'package:memora/domain/entities/group_member.dart';

class Group extends Equatable {
  const Group({
    required this.id,
    required this.ownerId,
    required this.name,
    this.memo,
    this.members = const [],
    this.events = const [],
  });

  final String id;
  final String ownerId;
  final String name;
  final String? memo;
  final List<GroupMember>? members;
  final List<GroupEvent>? events;

  Group copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? memo,
    List<GroupMember>? members,
    List<GroupEvent>? events,
  }) {
    return Group(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      memo: memo ?? this.memo,
      members: members ?? this.members,
      events: events ?? this.events,
    );
  }

  @override
  List<Object?> get props => [id, ownerId, name, memo, members, events];
}
