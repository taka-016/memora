import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void expectFloatingLabelVisible(WidgetTester tester, String label) {
  final labelBox = tester.renderObject<RenderBox>(find.text(label));
  final labelBounds = MatrixUtils.transformRect(
    labelBox.getTransformTo(null),
    labelBox.paintBounds,
  );
  RenderObject? ancestor = labelBox.parent;
  while (ancestor != null) {
    if (ancestor is RenderAbstractViewport && ancestor is RenderBox) {
      final viewportBounds = MatrixUtils.transformRect(
        ancestor.getTransformTo(null),
        ancestor.paintBounds,
      );
      expect(
        labelBounds.top,
        greaterThanOrEqualTo(viewportBounds.top),
        reason: '入力済みのラベル「$label」がスクロール領域の上端で切れないこと',
      );
    }
    ancestor = ancestor.parent;
  }
}
