import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NavigationItem {
  groupTimeline,
  mapDisplay,
  groupManagement,
  memberManagement,
  settings,
  accountSettings,
}

final navigationNotifierProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
      return NavigationNotifier();
    });

class NavigationState {
  final NavigationItem selectedItem;

  const NavigationState({required this.selectedItem});

  NavigationState copyWith({NavigationItem? selectedItem}) {
    return NavigationState(selectedItem: selectedItem ?? this.selectedItem);
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier()
    : super(const NavigationState(selectedItem: NavigationItem.groupTimeline));

  void selectItem(NavigationItem item) {
    state = state.copyWith(selectedItem: item);
  }
}
