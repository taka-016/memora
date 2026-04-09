import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group/timeline_row_settings.dart';

void main() {
  group('TimelineRowSettings', () {
    test('未保存時の既定値は旅行、イベント、DVC、メンバー行の順にする', () {
      final settings = TimelineRowSettings.defaults(
        groupId: 'group-1',
        memberIds: const ['member-1', 'member-2'],
      );

      expect(settings.groupId, 'group-1');
      expect(
        settings.rows.map((row) => row.rowId),
        ['trip', 'group_event', 'dvc', 'member:member-1', 'member:member-2'],
      );
      expect(settings.rows.map((row) => row.orderIndex), [0, 1, 2, 3, 4]);
      expect(settings.rows.every((row) => row.isVisible), isTrue);
    });

    test('同じrowIdが重複する設定は作成できない', () {
      expect(
        () => TimelineRowSettings(
          groupId: 'group-1',
          rows: const [
            TimelineRowSetting(rowId: 'trip', isVisible: true, orderIndex: 0),
            TimelineRowSetting(rowId: 'trip', isVisible: false, orderIndex: 1),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
