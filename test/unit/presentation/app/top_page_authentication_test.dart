import 'package:flutter_test/flutter_test.dart';

import 'top_page_test_support.dart';

void main() {
  final context = TopPageTestContext();

  setUp(context.setUpContext);

  group('TopPage 認証状態変更', context.registerAuthenticationTests);
}
