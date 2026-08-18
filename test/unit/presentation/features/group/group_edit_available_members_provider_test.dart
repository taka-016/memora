import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/member/get_managed_members_usecase.dart';
import 'package:memora/presentation/features/group/group_management.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'group_edit_available_members_provider_test.mocks.dart';

@GenerateMocks([GetManagedMembersUsecase])
void main() {
  const currentMember = MemberDto(id: 'member-1', displayName: '太郎');
  const availableMember = MemberDto(id: 'member-2', displayName: '花子');
  const groupId = 'group-1';

  late MockGetManagedMembersUsecase getMembersUsecase;
  late ProviderContainer container;

  setUp(() {
    getMembersUsecase = MockGetManagedMembersUsecase();
    container = ProviderContainer(
      overrides: [
        getManagedMembersUsecaseProvider.overrideWithValue(getMembersUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('groupEditAvailableMembersProvider', () {
    test('管理対象メンバーを編集対象グループのメンバーへ変換する', () async {
      when(
        getMembersUsecase.execute(currentMember),
      ).thenAnswer((_) async => const [availableMember]);
      final provider = groupEditAvailableMembersProvider((
        currentMember: currentMember,
        groupId: groupId,
      ));
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      final members = await container.read(provider.future);

      expect(members, hasLength(1));
      expect(members.single.memberId, availableMember.id);
      expect(members.single.groupId, groupId);
    });

    test('取得失敗を呼び出し元へ伝播する', () async {
      when(
        getMembersUsecase.execute(currentMember),
      ).thenThrow(TestException('メンバー取得失敗'));
      final provider = groupEditAvailableMembersProvider((
        currentMember: currentMember,
        groupId: groupId,
      ));
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      await expectLater(
        container.read(provider.future),
        throwsA(isA<TestException>()),
      );
    });
  });
}
