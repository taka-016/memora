import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';

class GroupWithMembers {
  final Group group;
  final List<Member> members;

  GroupWithMembers({required this.group, required this.members});
}
