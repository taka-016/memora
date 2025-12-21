import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';

class FakeCurrentMemberNotifier extends CurrentMemberNotifier {
  FakeCurrentMemberNotifier(this._state);

  final CurrentMemberState _state;

  factory FakeCurrentMemberNotifier.loading() {
    return FakeCurrentMemberNotifier(const CurrentMemberState.loading());
  }

  factory FakeCurrentMemberNotifier.loaded(MemberDto member) {
    return FakeCurrentMemberNotifier(CurrentMemberState.loaded(member));
  }

  factory FakeCurrentMemberNotifier.error(String message) {
    return FakeCurrentMemberNotifier(CurrentMemberState.error(message));
  }

  @override
  CurrentMemberState build() {
    return _state;
  }
}
