import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/composition_root/providers/account_providers.dart';
import 'package:memora/composition_root/providers/member_providers.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../application/usecases/member/check_member_exists_usecase_test.mocks.dart';
import '../member/current_member_notifier_test.mocks.dart';
import 'auth_notifier_test.mocks.dart';

void main() {
  testWidgets('認証の本人情報を再利用しログアウト後の別利用者へ引き継がず手動取得は更新する', (tester) async {
    final controller = StreamController<UserDto?>();
    addTearDown(controller.close);
    final observe = MockObserveAuthStateChangesUseCase();
    final validate = MockValidateCurrentUserTokenUseCase();
    final query = MockMemberQueryService();
    final current = MockGetCurrentMemberUseCase();
    when(observe.execute()).thenAnswer((_) => controller.stream);
    when(validate.execute()).thenAnswer((_) async {});
    var account = 'a';
    when(query.getMemberByAccountId(any)).thenAnswer((call) async => MemberDto(id: 'member-${call.positionalArguments.single}', displayName: '本人'));
    when(current.execute()).thenAnswer((_) => query.getMemberByAccountId(account));
    final container = ProviderContainer(overrides: [
      observeAuthStateChangesUseCaseProvider.overrideWithValue(observe),
      validateCurrentUserTokenUseCaseProvider.overrideWithValue(validate),
      memberQueryServiceProvider.overrideWithValue(query),
      getCurrentMemberUsecaseProvider.overrideWithValue(current),
    ]);
    addTearDown(container.dispose);
    container.listen(currentMemberNotifierProvider, (_, _) {});
    controller.add(const UserDto(id: 'a', loginId: 'a@example.com', isVerified: true));
    await tester.pump();
    expect(container.read(currentMemberNotifierProvider).member?.id, 'member-a');
    verify(query.getMemberByAccountId('a')).called(1);
    verifyNever(current.execute());
    final old = Completer<MemberDto?>();
    when(current.execute()).thenAnswer((_) => old.future);
    final oldLoad = container.read(currentMemberNotifierProvider.notifier).load();
    controller.add(null);
    await tester.pump();
    expect(container.read(currentMemberNotifierProvider).member, isNull);
    account = 'b';
    controller.add(const UserDto(id: 'b', loginId: 'b@example.com', isVerified: true));
    await tester.pump();
    expect(container.read(authNotifierProvider).user?.id, 'b');
    expect(container.read(currentMemberNotifierProvider).member?.id, 'member-b');
    old.complete(const MemberDto(id: 'member-a', displayName: '古い取得'));
    await oldLoad;
    expect(container.read(currentMemberNotifierProvider).member?.id, 'member-b');
    verify(query.getMemberByAccountId('b')).called(1);
    when(current.execute()).thenAnswer((_) async => const MemberDto(id: 'member-b', displayName: '更新済み'));
    await container.read(currentMemberNotifierProvider.notifier).load();
    expect(container.read(currentMemberNotifierProvider).member?.displayName, '更新済み');
  });
}
