import 'package:memora/domain/entities/member/member_event.dart';

abstract class MemberEventRepository {
  Future<void> saveMemberEvent(MemberEvent memberEvent);
  Future<void> deleteMemberEvent(String memberEventId);
  Future<void> deleteMemberEventsByMemberId(String memberId);
}
