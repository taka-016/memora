import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/usecases/member/save_member_event_usecase.dart';
import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/domain/repositories/member/member_event_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'save_member_event_usecase_test.mocks.dart';

@GenerateMocks([MemberEventRepository])
void main() {
  group('SaveMemberEventUsecase', () {
    late MockMemberEventRepository mockMemberEventRepository;
    late SaveMemberEventUsecase usecase;

    setUp(() {
      mockMemberEventRepository = MockMemberEventRepository();
      usecase = SaveMemberEventUsecase(mockMemberEventRepository);
    });

    test('MemberEventDtoをリポジトリ契約へ変換して保存し保存IDを返す', () async {
      const dto = MemberEventDto(
        id: '',
        memberId: 'member-1',
        year: 2026,
        memo: '入学式',
      );
      when(
        mockMemberEventRepository.saveMemberEvent(any),
      ).thenAnswer((_) async => 'saved-event-id');

      final result = await usecase.execute(dto);

      expect(
        result,
        const MemberEventDto(
          id: 'saved-event-id',
          memberId: 'member-1',
          year: 2026,
          memo: '入学式',
        ),
      );
      verify(
        mockMemberEventRepository.saveMemberEvent(
          const MemberEvent(
            id: '',
            memberId: 'member-1',
            year: 2026,
            memo: '入学式',
          ),
        ),
      ).called(1);
    });
  });
}
