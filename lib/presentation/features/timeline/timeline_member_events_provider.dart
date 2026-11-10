import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/composition_root/providers/member_providers.dart';
import 'package:memora/presentation/features/timeline/timeline_rows_refresh_provider.dart';

part 'timeline_member_events_provider.g.dart';

@Riverpod(retry: _noRetry)
Future<Map<int, MemberEventDto>> timelineMemberEventsByYear(
  Ref ref, {
  required String groupId,
  required String memberId,
}) async {
  ref.watch(timelineRowsRefreshProvider);
  final events = await ref.watch(getMemberEventsUsecaseProvider).execute([
    memberId,
  ], groupId: groupId);
  return {for (final event in events) event.year: event};
}

Duration? _noRetry(int retryCount, Object error) => null;
