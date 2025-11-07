import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/value_objects/order_by.dart';

void main() {
  group('OrderBy', () {
    test('同じフィールドと順序なら等価になる', () {
      const order1 = OrderBy('createdAt', descending: true);
      const order2 = OrderBy('createdAt', descending: true);

      expect(order1, equals(order2));
      expect(order1.hashCode, equals(order2.hashCode));
    });

    test('propsにはfieldとdescendingが含まれる', () {
      const order = OrderBy('updatedAt', descending: false);

      expect(order.props, ['updatedAt', false]);
    });

    test('toStringで状態が確認できる', () {
      const order = OrderBy('name', descending: true);

      expect(order.toString(), 'OrderBy(field: name, descending: true)');
    });
  });
}
