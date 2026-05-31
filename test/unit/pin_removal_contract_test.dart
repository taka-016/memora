import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pins廃止契約', () {
    test('pins専用の主要ファイルが存在しないこと', () {
      const removedPaths = [
        'lib/domain/entities/trip/pin.dart',
        'lib/application/dtos/trip/pin_dto.dart',
        'lib/application/mappers/trip/pin_mapper.dart',
        'lib/application/queries/trip/pin_query_service.dart',
        'lib/application/usecases/trip/get_pins_by_member_id_usecase.dart',
        'lib/infrastructure/mappers/trip/firestore_pin_mapper.dart',
        'lib/infrastructure/queries/trip/firestore_pin_query_service.dart',
        'lib/presentation/shared/sheets/pin_detail_bottom_sheet.dart',
      ];

      for (final path in removedPaths) {
        expect(File(path).existsSync(), isFalse, reason: path);
      }
    });
  });
}
