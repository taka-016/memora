import 'dart:async';

import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/logging/device_app_log.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';
import 'package:memora/presentation/notifiers/auth/auth_state.dart';

import '../../../../helpers/fake_auth_notifier.dart';

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

class _InitializingAuth extends FakeAuthNotifier {
  _InitializingAuth() : super(const AuthState.loading());

  void authenticate() {
    state = const AuthState.authenticated(
      UserDto(id: 'user', loginId: 'test@example.com', isVerified: true),
    );
  }
}

@GenerateMocks([GetCurrentMemberUseCase])
void main() {
  testWidgets('認証完了後だけ本人情報を取得しタイムアウト後の再試行と遅延完了を扱う', (tester) async {
    final previousLog = logger;
    logger = const SilentAppLog();
    addTearDown(() => logger = previousLog);
    final auth = _InitializingAuth();
    final pending = Completer<MemberDto?>();
    final useCase = MockGetCurrentMemberUseCase();
    when(useCase.execute()).thenAnswer((_) => pending.future);
    final container = ProviderContainer(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.online),
        authNotifierProvider.overrideWith(() => auth),
        getCurrentMemberUsecaseProvider.overrideWithValue(useCase),
      ],
    );
    addTearDown(container.dispose);
    container.listen(currentMemberNotifierProvider, (_, _) {});
    await tester.pump();
    verifyNever(useCase.execute());
    auth.authenticate();
    await tester.pump();
    verify(useCase.execute()).called(1);
    await tester.pump(const Duration(seconds: 15));
    expect(
      container.read(currentMemberNotifierProvider).status,
      CurrentMemberStatus.error,
    );
    expect(container.read(currentMemberNotifierProvider).canRetry, isTrue);
    expect(auth.logoutCalled, isFalse);
    const member = MemberDto(
      id: 'member',
      accountId: 'user',
      displayName: '本人',
    );
    when(useCase.execute()).thenAnswer((_) async => member);
    final retry = container.read(currentMemberNotifierProvider.notifier).load();
    await tester.pump();
    await retry;
    expect(container.read(currentMemberNotifierProvider).member, member);
    pending.complete(
      const MemberDto(id: 'stale', accountId: 'user', displayName: '古い結果'),
    );
    await tester.pump();
    expect(container.read(currentMemberNotifierProvider).member, member);
    expect(auth.logoutCalled, isFalse);
  });

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
