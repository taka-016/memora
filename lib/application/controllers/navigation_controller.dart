import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NavigationItem {
  groupTimeline,
  mapDisplay,
  groupManagement,
  memberManagement,
  settings,
  accountSettings,
}

class NavigationState {
  final NavigationItem selectedItem;

  const NavigationState({required this.selectedItem});

  NavigationState copyWith({NavigationItem? selectedItem}) {
    return NavigationState(selectedItem: selectedItem ?? this.selectedItem);
  }
}

class NavigationController extends StateNotifier<NavigationState> {
  NavigationController()
    : super(const NavigationState(selectedItem: NavigationItem.groupTimeline));

  void selectItem(NavigationItem item) {
    state = state.copyWith(selectedItem: item);
  }
}

final navigationControllerProvider =
    StateNotifierProvider<NavigationController, NavigationState>((ref) {
      return NavigationController();
    });
