import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/composition_root/providers/member_providers.dart';
import 'package:memora/composition_root/providers/startup_common_data_providers.dart';
import 'package:memora/presentation/notifiers/startup/startup_common_data_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';

final memberMutationCoordinatorProvider = Provider<MemberMutationCoordinator>(
  MemberMutationCoordinator.new,
);

class MemberMutationCoordinator {
  MemberMutationCoordinator(this.ref);

  final Ref ref;

  Future<void> createMember(
    MemberDto member, {
    required String ownerId,
    required Future<void> Function() refreshMembers,
  }) async {
    await ref.read(createMemberUsecaseProvider).execute(member, ownerId);
    await _refresh(refreshMembers);
  }

  Future<void> updateMember(
    MemberDto member, {
    required Future<void> Function() refreshMembers,
  }) async {
    await ref.read(updateMemberUsecaseProvider).execute(member);
    await _refresh(refreshMembers);
  }

  Future<void> deleteMember(
    String memberId, {
    int? expectedVersion,
    required Future<void> Function() refreshMembers,
  }) async {
    await ref
        .read(deleteMemberUsecaseProvider)
        .execute(memberId, expectedVersion: expectedVersion);
    if (!ref.mounted) return;
    ref.read(groupTimelineGroupSelectionNotifierProvider.notifier).reset();
    await _refresh(refreshMembers);
  }

  Future<void> _refresh(Future<void> Function() refreshMembers) async {
    if (!ref.mounted) return;
    await refreshMembers();
    if (ref.mounted &&
        ref.read(startupCommonDataNotifierProvider.exists) &&
        ref.read(startupCommonDataOwnerProvider) != null) {
      await ref
          .read(startupCommonDataNotifierProvider.notifier)
          .refreshAfterChange();
    }
  }
}
