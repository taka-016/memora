import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/queries/group/group_event_query_service.dart';
import 'package:memora/application/usecases/group/get_group_events_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'get_group_events_usecase_test.mocks.dart';

@GenerateMocks([GroupEventQueryService])
void main() {
  group('GetGroupEventsUsecase', () {
    late MockGroupEventQueryService mockGroupEventQueryService;
    late GetGroupEventsUsecase usecase;

    setUp(() {
      mockGroupEventQueryService = MockGroupEventQueryService();
      usecase = GetGroupEventsUsecase(mockGroupEventQueryService);
    });

    test('groupIdに紐づくグループイベント一覧を年昇順で取得できる', () async {
      const groupId = 'group-1';
      const expected = [
        GroupEventDto(id: 'event-1', groupId: groupId, year: 2024, memo: '運動会'),
        GroupEventDto(
          id: 'event-2',
          groupId: groupId,
          year: 2025,
          memo: '修学旅行',
        ),
      ];

      when(
        mockGroupEventQueryService.getGroupEventsByGroupId(
          groupId,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => expected);

      final result = await usecase.execute(groupId);

      expect(result, expected);
      verify(
        mockGroupEventQueryService.getGroupEventsByGroupId(
          groupId,
          orderBy: anyNamed('orderBy'),
        ),
      ).called(1);
    });

    test('例外時は空リストを返す', () async {
      when(
        mockGroupEventQueryService.getGroupEventsByGroupId(
          any,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenThrow(TestException('取得失敗'));

      final result = await usecase.execute('group-1');

      expect(result, isEmpty);
    });
  });
}
