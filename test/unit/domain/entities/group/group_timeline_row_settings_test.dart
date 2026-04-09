import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group/group_timeline_row_settings.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('GroupTimelineRowSettings', () {
    test('同じrowIdを含む設定は作成できない', () {
      expect(
        () => GroupTimelineRowSettings(
          groupId: 'group1',
          rows: const [
            GroupTimelineRowSetting(
              rowId: 'trip',
              rowType: GroupTimelineRowType.trip,
              orderIndex: 0,
              isVisible: true,
            ),
            GroupTimelineRowSetting(
              rowId: 'trip',
              rowType: GroupTimelineRowType.trip,
              orderIndex: 1,
              isVisible: false,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rowsは外部から直接変更できない', () {
      final rows = [
        const GroupTimelineRowSetting(
          rowId: 'trip',
          rowType: GroupTimelineRowType.trip,
          orderIndex: 0,
          isVisible: true,
        ),
      ];

      final settings = GroupTimelineRowSettings(groupId: 'group1', rows: rows);
      rows.add(
        const GroupTimelineRowSetting(
          rowId: 'dvc',
          rowType: GroupTimelineRowType.dvc,
          orderIndex: 1,
          isVisible: true,
        ),
      );

      expect(settings.rows.map((row) => row.rowId), ['trip']);
      expect(
        () => settings.rows.add(
          const GroupTimelineRowSetting(
            rowId: 'group_event',
            rowType: GroupTimelineRowType.groupEvent,
            orderIndex: 1,
            isVisible: true,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
