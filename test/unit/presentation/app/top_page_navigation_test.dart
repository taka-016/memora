import 'package:flutter_test/flutter_test.dart';

import 'top_page_test_support.dart';

void main() {
  final context = TopPageTestContext();

  setUp(context.setUpContext);

  group('TopPage 通常ナビゲーション', context.registerNavigationTests);
}
