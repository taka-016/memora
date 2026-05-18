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

    test('アプリで使用する複合インデックスをすべて定義している', () {
      expect(indexes, hasLength(_expectedIndexes.length));

      for (final expectedIndex in _expectedIndexes) {
        expect(indexes, _containsIndex(expectedIndex));
      }
    });
  });
}

const _expectedIndexes = [
  _ExpectedFirestoreIndex(
    collectionGroup: 'dvc_limited_points',
    fields: [
      _ExpectedFirestoreIndexField('groupId'),
      _ExpectedFirestoreIndexField('startYearMonth'),
      _ExpectedFirestoreIndexField('__name__'),
    ],
  ),
  _ExpectedFirestoreIndex(
    collectionGroup: 'dvc_point_contracts',
    fields: [
      _ExpectedFirestoreIndexField('groupId'),
      _ExpectedFirestoreIndexField('contractName'),
      _ExpectedFirestoreIndexField('__name__'),
    ],
  ),
  _ExpectedFirestoreIndex(
    collectionGroup: 'dvc_point_contracts',
    fields: [
      _ExpectedFirestoreIndexField('groupId'),
      _ExpectedFirestoreIndexField('contractStartYearMonth'),
      _ExpectedFirestoreIndexField('__name__'),
    ],
  ),
  _ExpectedFirestoreIndex(
    collectionGroup: 'dvc_point_usages',
    fields: [
      _ExpectedFirestoreIndexField('groupId'),
      _ExpectedFirestoreIndexField('usageYearMonth'),
      _ExpectedFirestoreIndexField('__name__'),
    ],
  ),
  _ExpectedFirestoreIndex(
    collectionGroup: 'group_events',
    fields: [
      _ExpectedFirestoreIndexField('groupId'),
      _ExpectedFirestoreIndexField('year'),
      _ExpectedFirestoreIndexField('__name__'),
    ],
  ),
  _ExpectedFirestoreIndex(
    collectionGroup: 'groups',
    fields: [
      _ExpectedFirestoreIndexField('ownerId'),
      _ExpectedFirestoreIndexField('name'),
      _ExpectedFirestoreIndexField('__name__'),
    ],
  ),
  _ExpectedFirestoreIndex(
    collectionGroup: 'itinerary_items',
    fields: [
      _ExpectedFirestoreIndexField('tripId'),
      _ExpectedFirestoreIndexField('orderIndex'),
      _ExpectedFirestoreIndexField('__name__'),
    ],
  ),
  _ExpectedFirestoreIndex(
    collectionGroup: 'member_events',
    fields: [
      _ExpectedFirestoreIndexField('memberId'),
      _ExpectedFirestoreIndexField('year'),
      _ExpectedFirestoreIndexField('__name__'),
    ],
  ),
  _ExpectedFirestoreIndex(
    collectionGroup: 'members',
    fields: [
      _ExpectedFirestoreIndexField('ownerId'),
      _ExpectedFirestoreIndexField('displayName'),
      _ExpectedFirestoreIndexField('__name__'),
    ],
  ),
  _ExpectedFirestoreIndex(
    collectionGroup: 'pin_details',
    fields: [
      _ExpectedFirestoreIndexField('pinId'),
      _ExpectedFirestoreIndexField('startDate'),
      _ExpectedFirestoreIndexField('__name__'),
    ],
  ),
  _ExpectedFirestoreIndex(
    collectionGroup: 'pins',
    fields: [
      _ExpectedFirestoreIndexField('tripId'),
      _ExpectedFirestoreIndexField('visitStartDateTime'),
      _ExpectedFirestoreIndexField('__name__'),
    ],
  ),
  _ExpectedFirestoreIndex(
    collectionGroup: 'tasks',
    fields: [
      _ExpectedFirestoreIndexField('tripId'),
      _ExpectedFirestoreIndexField('orderIndex'),
      _ExpectedFirestoreIndexField('__name__'),
    ],
  ),
  _ExpectedFirestoreIndex(
    collectionGroup: 'trip_entries',
    fields: [
      _ExpectedFirestoreIndexField('groupId'),
      _ExpectedFirestoreIndexField('year'),
      _ExpectedFirestoreIndexField('startDate'),
      _ExpectedFirestoreIndexField('__name__'),
    ],
  ),
];

Matcher _containsIndex(_ExpectedFirestoreIndex expectedIndex) {
  return contains(
    predicate<dynamic>(
      (index) => expectedIndex.matches(index as Map<String, dynamic>),
      'collectionGroup: ${expectedIndex.collectionGroup}, '
      'fields: ${expectedIndex.fields}',
    ),
  );
}

class _ExpectedFirestoreIndex {
  const _ExpectedFirestoreIndex({
    required this.collectionGroup,
    required this.fields,
  });

  final String collectionGroup;
  final List<_ExpectedFirestoreIndexField> fields;

  bool matches(Map<String, dynamic> index) {
    final actualFields = index['fields'] as List<dynamic>;

    return index['collectionGroup'] == collectionGroup &&
        index['queryScope'] == 'COLLECTION' &&
        index['density'] == 'SPARSE_ALL' &&
        actualFields.length == fields.length &&
        fields.indexed.every((entry) {
          return entry.$2.matches(
            actualFields[entry.$1] as Map<String, dynamic>,
          );
        });
  }
}

class _ExpectedFirestoreIndexField {
  const _ExpectedFirestoreIndexField(this.fieldPath);

  final String fieldPath;

  bool matches(Map<String, dynamic> field) {
    return field['fieldPath'] == fieldPath && field['order'] == 'ASCENDING';
  }

  @override
  String toString() {
    return '$fieldPath ASCENDING';
  }
}
