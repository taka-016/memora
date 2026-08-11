import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/timeline/group_timeline_navigation_view.dart';

void main() {
  test('現在のグループルートからIndexedStackのindexを決定する', () {
    expect(groupTimelineStackIndex(groupId: null), 0);
    expect(groupTimelineStackIndex(groupId: 'group-1'), 1);
  });
}
