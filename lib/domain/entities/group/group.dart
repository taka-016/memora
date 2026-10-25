import 'package:equatable/equatable.dart';
import 'package:memora/domain/entities/group/group_member.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class Group extends Equatable {
  Group({
    this.version,
    required this.id,
    required this.ownerId,
    required this.name,
    this.memo,
    this.color = '#4CAF50',
    List<GroupMember>? originalMembers,
    List<GroupMember>? members,
  }) : originalMembers = List.unmodifiable(
         originalMembers ?? members ?? const [],
       ),
       members = List.unmodifiable(members ?? const []) {
    final rgb = RegExp(r'^#[0-9a-fA-F]{6}$');
    if (!rgb.hasMatch(color) ||
        this.members.any((member) => !rgb.hasMatch(member.color))) {
      throw ValidationException('色は#RRGGBB形式で指定してください');
    }
    if (members != null) {
      final memberIds = <String>{};
      for (final member in members) {
        if (!memberIds.add(member.memberId)) {
          throw ValidationException('メンバーIDが重複しています: ${member.memberId}');
        }
      }
    }
  }

  final int? version;
  final String id;
  final String ownerId;
  final String color;
  final String name;
  final String? memo;
  final List<GroupMember> members;
  final List<GroupMember> originalMembers;

  Group copyWith({
    int? version,
    String? color,
    String? id,
    String? ownerId,
    String? name,
    String? memo,
    List<GroupMember>? members,
  }) {
    return Group(
      version: version ?? this.version,
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      color: color ?? this.color,
      name: name ?? this.name,
      memo: memo ?? this.memo,
      members: members ?? this.members,
      originalMembers: originalMembers,
    );
  }

  @override
  List<Object?> get props => [
    color,
    version,
    id,
    ownerId,
    name,
    memo,
    members,
    originalMembers,
  ];
}
