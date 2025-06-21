import 'package:memora/domain/entities/managed_member.dart';

abstract class ManagedMemberRepository {
  Future<List<ManagedMember>> getManagedMembers();
  Future<void> saveManagedMember(ManagedMember managedMember);
  Future<void> deleteManagedMember(String managedMemberId);
  Future<List<ManagedMember>> getManagedMembersByMemberId(String memberId);
  Future<List<ManagedMember>> getManagedMembersByManagedMemberId(
    String managedMemberId,
  );
}
