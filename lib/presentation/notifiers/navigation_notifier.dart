import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NavigationItem {
  groupTimeline,
  dvcPointCalculation,
  mapDisplay,
  groupManagement,
  memberManagement,
  settings,
  accountSettings,
}

final navigationNotifierProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(
      NavigationNotifier.new,
    );

class NavigationState {
  final NavigationItem selectedItem;

  const NavigationState({required this.selectedItem});

  NavigationState copyWith({NavigationItem? selectedItem}) {
    return NavigationState(selectedItem: selectedItem ?? this.selectedItem);
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() {
    return const NavigationState(selectedItem: NavigationItem.groupTimeline);
  }

  void selectItem(NavigationItem item) {
    state = state.copyWith(selectedItem: item);
  }

  void resetToDefault() {
    state = const NavigationState(selectedItem: NavigationItem.groupTimeline);
  }
}
