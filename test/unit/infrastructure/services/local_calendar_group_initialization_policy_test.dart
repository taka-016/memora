import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/services/local_calendar_group_initialization_policy.dart';

void main() {
  test('復元元の利用者を別Container・プロセスでも初期選択せず端末の表示設定に触れない', () async {
    final folder = await Directory.systemTemp.createTemp('calendar-restore-history-');
    addTearDown(() => folder.delete(recursive: true));
    final policy = LocalCalendarGroupInitializationPolicy(directory: () async => folder);
    expect(await policy.canInitialize('offline:new'), isTrue);
    await policy.markRestored('offline:restored');
    final restarted = LocalCalendarGroupInitializationPolicy(directory: () async => folder);
    expect(await restarted.canInitialize('offline:restored'), isFalse);
    expect(await restarted.canInitialize('offline:new'), isTrue);
    expect(folder.listSync().every((file) => !file.path.contains('calendar_groups_')), isTrue);
  });
}
