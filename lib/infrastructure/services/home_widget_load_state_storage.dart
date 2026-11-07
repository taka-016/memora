import 'package:home_widget/home_widget.dart';

class HomeWidgetLoadStateStorage {
  const HomeWidgetLoadStateStorage();

  Future<void> track(
    String key,
    Future<void> Function() action, {
    required Future<void> Function() update,
  }) async {
    final request = 'loading:${DateTime.now().microsecondsSinceEpoch}';
    await HomeWidget.saveWidgetData<String>(key, request);
    try {
      await update();
      await action();
      if (await HomeWidget.getWidgetData<String>(key) == request) {
        await HomeWidget.saveWidgetData<String>(key, null);
      }
    } catch (_) {
      if (await HomeWidget.getWidgetData<String>(key) == request) {
        await HomeWidget.saveWidgetData<String>(key, 'failed');
      }
      rethrow;
    } finally {
      await update();
    }
  }
}
