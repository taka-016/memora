import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_state_notifier.g.dart';

@riverpod
class EditStateNotifier extends _$EditStateNotifier {
  @override
  EditState build() {
    return const EditState();
  }

  void setDirty(bool isDirty) {
    if (state.isDirty == isDirty) {
      return;
    }
    state = state.copyWith(isDirty: isDirty);
  }

  void reset() {
    state = const EditState();
  }
}

class EditState {
  const EditState({this.isDirty = false});

  final bool isDirty;

  EditState copyWith({bool? isDirty}) {
    return EditState(isDirty: isDirty ?? this.isDirty);
  }
}
