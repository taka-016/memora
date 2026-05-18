import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('firestore.indexes.json', () {
    late List<dynamic> indexes;

    setUpAll(() {
      final indexFile = File('firestore.indexes.json');
      final indexJson =
          jsonDecode(indexFile.readAsStringSync()) as Map<String, dynamic>;
      indexes = indexJson['indexes'] as List<dynamic>;
    });

    test('itinerary_itemsを旅行IDで絞りorderIndex昇順で取得する複合インデックスを定義している', () {
      final hasItineraryItemsIndex = indexes.any((index) {
        final indexMap = index as Map<String, dynamic>;
        final fields = indexMap['fields'] as List<dynamic>;

        return indexMap['collectionGroup'] == 'itinerary_items' &&
            indexMap['queryScope'] == 'COLLECTION' &&
            _hasField(fields, 'tripId', 'ASCENDING') &&
            _hasField(fields, 'orderIndex', 'ASCENDING') &&
            _hasField(fields, '__name__', 'ASCENDING');
      });

      expect(hasItineraryItemsIndex, isTrue);
    });
  });
}

bool _hasField(List<dynamic> fields, String fieldPath, String order) {
  return fields.any((field) {
    final fieldMap = field as Map<String, dynamic>;
    return fieldMap['fieldPath'] == fieldPath && fieldMap['order'] == order;
  });
}
