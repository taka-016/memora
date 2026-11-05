import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/member_providers.dart';

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';
import 'package:memora/presentation/notifiers/auth/auth_state.dart';

enum CurrentMemberStatus { loading, loaded, error }

class CurrentMemberState extends Equatable {
  const CurrentMemberState._({
    required this.status,
    this.member,
    this.message = '',
    this.canRetry = false,
  });

  const CurrentMemberState.loading()
    : this._(status: CurrentMemberStatus.loading);

  const CurrentMemberState.loaded(MemberDto? member)
    : this._(status: CurrentMemberStatus.loaded, member: member);

  const CurrentMemberState.error(String message, {bool canRetry = false})
    : this._(
        status: CurrentMemberStatus.error,
        message: message,
        canRetry: canRetry,
      );

  final CurrentMemberStatus status;
  final MemberDto? member;
  final String message;
  final bool canRetry;

  @override
  List<Object?> get props => [status, member, message, canRetry];
}

final currentMemberNotifierProvider =
    NotifierProvider<CurrentMemberNotifier, CurrentMemberState>(
      CurrentMemberNotifier.new,
    );

class CurrentMemberNotifier extends Notifier<CurrentMemberState> {
  GetCurrentMemberUseCase get _getCurrentMemberUseCase =>
      ref.read(getCurrentMemberUsecaseProvider);

  @override
  CurrentMemberState build() {
    final authenticationAvailable = ref
        .watch(appCapabilitiesProvider)
        .availability(AppFeature.authentication)
        .isAvailable;
    if (authenticationAvailable) {
      ref.listen<AuthState>(authNotifierProvider, (previous, next) {
        if (previous?.status == next.status) {
          return;
        }

        if (next.status == AuthStatus.authenticated) {
          unawaited(load());
          return;
        }

        if (next.status == AuthStatus.unauthenticated) {
          state = const CurrentMemberState.loading();
        }
      });
    }

    if (!authenticationAvailable ||
        ref.read(authNotifierProvider).isAuthenticated) {
      Future.microtask(() {
        if (ref.mounted) unawaited(load());
      });
    }

    return const CurrentMemberState.loading();
  }

  Future<void> load() async {
    final stopwatch = Stopwatch()..start();
    if (kDebugMode) logger.i('起動データ: 本人情報取得 開始');
    try {
      state = const CurrentMemberState.loading();
      final authenticationAvailable = ref
          .read(appCapabilitiesProvider)
          .availability(AppFeature.authentication)
          .isAvailable;
      final request = _getCurrentMemberUseCase.execute();
      final member = authenticationAvailable
          ? await request.timeout(const Duration(seconds: 15))
          : await request;
      if (kDebugMode) {
        logger.i('起動データ: 本人情報取得 完了（${stopwatch.elapsedMilliseconds}ms）');
      }
      if (!ref.mounted) return;
      state = CurrentMemberState.loaded(member);
    } on TimeoutException catch (e, stack) {
      logger.w('本人情報の取得がタイムアウトしました', error: e, stackTrace: stack);
      if (!ref.mounted) return;
      state = const CurrentMemberState.error(
        '本人情報の取得に時間がかかっています。再試行してください。',
        canRetry: true,
      );
    } catch (e, stack) {
      logger.e(
        'CurrentMemberNotifier.load: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (!ref.mounted) return;
      state = CurrentMemberState.error(
        ref
                .read(appCapabilitiesProvider)
                .availability(AppFeature.authentication)
                .isAvailable
            ? 'メンバー情報の取得に失敗しました。再度ログインしてください。'
            : '本人情報の取得に失敗しました。再試行してください。',
      );
    }
  }
}
