import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/queries/member/member_event_query_service.dart';
import 'package:memora/application/usecases/member/get_member_events_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'get_member_events_usecase_test.mocks.dart';

@GenerateMocks([MemberEventQueryService])
void main() {
  group('GetMemberEventsUsecase', () {
    late MockMemberEventQueryService mockMemberEventQueryService;
    late GetMemberEventsUsecase usecase;

    setUp(() {
      mockMemberEventQueryService = MockMemberEventQueryService();
      usecase = GetMemberEventsUsecase(mockMemberEventQueryService);
    });

    test('memberId一覧に紐づくメンバーイベント一覧を年昇順で取得できる', () async {
      const expected = [
        MemberEventDto(
          id: 'event-1',
          memberId: 'member-1',
          year: 2026,
          memo: '入学式',
        ),
        MemberEventDto(
          id: 'event-2',
          memberId: 'member-2',
          year: 2027,
          memo: '卒業式',
        ),
      ];

      when(
        mockMemberEventQueryService.getMemberEventsByMemberIds(const [
          'member-1',
          'member-2',
        ], orderBy: anyNamed('orderBy')),
      ).thenAnswer((_) async => expected);

      final result = await usecase.execute(const ['member-1', 'member-2']);

      expect(result, expected);
      verify(
        mockMemberEventQueryService.getMemberEventsByMemberIds(const [
          'member-1',
          'member-2',
        ], orderBy: anyNamed('orderBy')),
      ).called(1);
    });

    test('例外時は空リストを返す', () async {
      when(
        mockMemberEventQueryService.getMemberEventsByMemberIds(
          any,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenThrow(TestException('取得失敗'));

      final result = await usecase.execute(const ['member-1']);

      expect(result, isEmpty);
    });
  });
}
