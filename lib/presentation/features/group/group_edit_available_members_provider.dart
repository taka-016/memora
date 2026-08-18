import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/group/group_member_mapper.dart';
import 'package:memora/application/usecases/member/get_managed_members_usecase.dart';

typedef GroupEditAvailableMembersQuery = ({
  MemberDto currentMember,
  String groupId,
});

final groupEditAvailableMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMemberDto>, GroupEditAvailableMembersQuery>((
      ref,
      query,
    ) async {
      final members = await ref
          .watch(getManagedMembersUsecaseProvider)
          .execute(query.currentMember);
      return GroupMemberMapper.fromMemberList(members, query.groupId);
    }, retry: (_, _) => null);
