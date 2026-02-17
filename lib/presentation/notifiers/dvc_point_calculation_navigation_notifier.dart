import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';

enum DvcPointCalculationScreenState { groupList, calculation }

final dvcPointCalculationNavigationNotifierProvider =
    NotifierProvider<
      DvcPointCalculationNavigationNotifier,
      DvcPointCalculationNavigationState
    >(DvcPointCalculationNavigationNotifier.new);

class DvcPointCalculationNavigationState {
  final DvcPointCalculationScreenState currentScreen;
  final GroupDto? selectedGroup;

  const DvcPointCalculationNavigationState({
    required this.currentScreen,
    this.selectedGroup,
  });

  DvcPointCalculationNavigationState copyWith({
    DvcPointCalculationScreenState? currentScreen,
    GroupDto? selectedGroup,
    bool clearSelectedGroup = false,
  }) {
    return DvcPointCalculationNavigationState(
      currentScreen: currentScreen ?? this.currentScreen,
      selectedGroup: clearSelectedGroup
          ? null
          : (selectedGroup ?? this.selectedGroup),
    );
  }
}

class DvcPointCalculationNavigationNotifier
    extends Notifier<DvcPointCalculationNavigationState> {
  @override
  DvcPointCalculationNavigationState build() {
    return const DvcPointCalculationNavigationState(
      currentScreen: DvcPointCalculationScreenState.groupList,
    );
  }

  void showGroupList() {
    state = state.copyWith(
      currentScreen: DvcPointCalculationScreenState.groupList,
      clearSelectedGroup: true,
    );
  }

  void showCalculation(GroupDto selectedGroup) {
    state = state.copyWith(
      currentScreen: DvcPointCalculationScreenState.calculation,
      selectedGroup: selectedGroup,
    );
  }

  void resetToGroupList() {
    showGroupList();
  }

  int getStackIndex() {
    switch (state.currentScreen) {
      case DvcPointCalculationScreenState.groupList:
        return 0;
      case DvcPointCalculationScreenState.calculation:
        return 1;
    }
  }
}
