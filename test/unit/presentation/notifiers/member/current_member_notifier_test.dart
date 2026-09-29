import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';
import 'package:memora/composition_root/providers/member_providers.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'current_member_notifier_test.mocks.dart';

@GenerateMocks([GetCurrentMemberUseCase])
void main() {
  test('オフラインの本人取得失敗後に認証を使わず再試行する', () async {
    var authResolutions = 0;
    final useCase = MockGetCurrentMemberUseCase();
    when(useCase.execute()).thenThrow(TestException('読み込み失敗'));
    final container = ProviderContainer(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.offline),
        getCurrentMemberUsecaseProvider.overrideWithValue(useCase),
        authServiceProvider.overrideWith((ref) {
          authResolutions++;
          throw TestException('認証は利用しない');
        }),
      ],
    );
    addTearDown(container.dispose);
    final failed = Completer<void>();
    container.listen(currentMemberNotifierProvider, (_, state) {
      if (state.status == CurrentMemberStatus.error && !failed.isCompleted) {
        failed.complete();
      }
    });
    await failed.future;
    expect(authResolutions, 0);
    expect(
      container.read(currentMemberNotifierProvider).message,
      isNot(contains('ログイン')),
    );
    const member = MemberDto(id: 'local-member', displayName: '本人');
    when(useCase.execute()).thenAnswer((_) async => member);
    await container.read(currentMemberNotifierProvider.notifier).load();
    expect(container.read(currentMemberNotifierProvider).member, member);
    expect(authResolutions, 0);
  });
}
