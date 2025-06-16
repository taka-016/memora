import 'package:memora/domain/entities/member_event.dart';

abstract class MemberEventRepository {
  Future<List<MemberEvent>> getMemberEvents();
  Future<void> saveMemberEvent(MemberEvent memberEvent);
  Future<void> deleteMemberEvent(String memberEventId);
  Future<List<MemberEvent>> getMemberEventsByMemberId(String memberId);
}