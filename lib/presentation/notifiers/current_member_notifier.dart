import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/value_objects/auth_state.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';

enum CurrentMemberStatus { loading, loaded, error }

class CurrentMemberState extends Equatable {
  const CurrentMemberState._({
    required this.status,
    this.member,
    this.message = '',
  });

  const CurrentMemberState.loading()
    : this._(status: CurrentMemberStatus.loading);

  const CurrentMemberState.loaded(MemberDto? member)
    : this._(status: CurrentMemberStatus.loaded, member: member);

  const CurrentMemberState.error(String message)
    : this._(status: CurrentMemberStatus.error, message: message);

  final CurrentMemberStatus status;
  final MemberDto? member;
  final String message;

  @override
  List<Object?> get props => [status, member, message];
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

    Future.microtask(() {
      unawaited(load());
    });

    return const CurrentMemberState.loading();
  }

  Future<void> load() async {
    try {
      state = const CurrentMemberState.loading();
      final member = await _getCurrentMemberUseCase.execute();
      state = CurrentMemberState.loaded(member);
    } catch (e, stack) {
      logger.e(
        'CurrentMemberNotifier.load: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      state = const CurrentMemberState.error('メンバー情報の取得に失敗しました。再度ログインしてください。');
    }
  }
}
