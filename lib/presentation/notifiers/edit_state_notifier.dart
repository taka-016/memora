import 'package:flutter_riverpod/flutter_riverpod.dart';

final editStateNotifierProvider =
    AutoDisposeNotifierProvider<EditStateNotifier, EditState>(
      EditStateNotifier.new,
    );

class EditStateNotifier extends AutoDisposeNotifier<EditState> {
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
