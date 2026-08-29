import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('Task', () {
    test('orderIndexが負の場合はValidationExceptionを投げる', () {
      expect(
        () => Task(
          id: 'task001',
          tripId: 'trip001',
          orderIndex: -1,
          name: '準備',
          isCompleted: false,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('nameが空の場合はValidationExceptionを投げる', () {
      expect(
        () => Task(
          id: 'task001',
          tripId: 'trip001',
          orderIndex: 0,
          name: '  ',
          isCompleted: false,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
