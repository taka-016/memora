import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/queries/member/member_event_query_service.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/presentation/features/timeline/timeline_member_events_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'timeline_member_events_provider_test.mocks.dart';

@GenerateMocks([MemberEventQueryService])
void main() {
  test('同じメンバーと年の記録をグループ別の状態で取得する', () async {
    final query = MockMemberEventQueryService();
    for (final groupId in ['g1', 'g2']) {
      when(
        query.getMemberEventsByMemberIds(
          ['m'],
          groupId: groupId,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer(
        (_) async => [
          MemberEventDto(
            id: groupId,
            groupId: groupId,
            memberId: 'm',
            year: 2026,
            memo: groupId,
          ),
        ],
      );
    }
    final container = ProviderContainer(
      overrides: [memberEventQueryServiceProvider.overrideWithValue(query)],
    );
    addTearDown(container.dispose);
    for (final groupId in ['g1', 'g2']) {
      final provider = timelineMemberEventsByYearProvider(
        groupId: groupId,
        memberId: 'm',
      );
      container.listen(provider, (_, _) {});
      expect((await container.read(provider.future))[2026]!.memo, groupId);
    }
  });
}
