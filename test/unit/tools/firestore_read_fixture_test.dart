import 'package:flutter_test/flutter_test.dart';

import '../../../scripts/test/firestore_reads/fixture.dart';

void main() {
  Map<String, dynamic> dataset(List<Object> docs) => {
    'version': 1,
    'accounts': [
      {
        'id': 'a',
        'email': 'a@example.test',
        'password': 'test-password',
        'emailVerified': true,
      },
    ],
    'device': {
      'preferences': {},
      'widgets': [],
      'notificationPermission': 'granted',
    },
    'documents': docs,
  };
  final document = {
    'path': 'groups/g',
    'fields': {
      'name': '家族',
      'createdAt': {r'$timestamp': '2026-11-15T12:00:00+09:00'},
    },
  };
  test('JSONの繰り返しを展開し日時をRESTの型付き値へ変換する', () {
    final value = ReadFixture.parse(
      dataset([
        document,
        {
          'repeat': {
            'id': ['a', 'b'],
          },
          'path': r'members/${id}',
          'fields': {
            'group': {r'$reference': 'groups/g'},
            'name': r'名前${id}',
          },
        },
      ]),
    );
    expect(value.documents.map((d) => d.path), [
      'groups/g',
      'members/a',
      'members/b',
    ]);
    expect(value.collectionCounts, {'groups': 1, 'members': 2});
    expect(value.documents.first.fields['createdAt'], {
      'timestampValue': '2026-11-15T03:00:00.000Z',
    });
    expect(value.documents[1].fields['group'], {
      'referenceValue': 'projects/demo-memora-read-regression/databases/(default)/documents/groups/g',
    });
  });
  test('文書の重複・欠落参照・未知の型・解決できない変数を投入前に拒否する', () {
    for (final docs in [
      [document, document],
      [
        {
          'path': 'groups/g',
          'fields': {
            'ref': {r'$reference': 'members/missing'},
          },
        },
      ],
      [
        {
          'path': 'groups/g',
          'fields': {
            'at': {r'$timestamp': '2026-11-15'},
          },
        },
      ],
      [
        {
          'path': 'groups/g',
          'fields': {
            'x': {r'$unknown': 'x'},
          },
        },
      ],
      [
        {'path': r'groups/${missing}', 'fields': {}},
      ],
      [
        {'path': 'groups', 'fields': {}},
      ],
    ]) {
      expect(() => ReadFixture.parse(dataset(docs)), throwsFormatException);
    }
  });
  test('データセット内の認証アカウントと端末設定の不備を拒否する', () {
    for (final patch in [
      {
        'accounts': [
          {'id': 'a'},
        ],
      },
      {
        'accounts': [
          {
            'id': 'a',
            'email': 'a@example.test',
            'password': 'password',
            'emailVerified': true,
          },
          {
            'id': 'a',
            'email': 'b@example.test',
            'password': 'password',
            'emailVerified': true,
          },
        ],
      },
      {
        'device': {
          'preferences': {},
          'widgets': [],
          'notificationPermission': 'unknown',
        },
      },
    ]) {
      expect(
        () => ReadFixture.parse({
          ...dataset([document]),
          ...patch,
        }),
        throwsFormatException,
      );
    }
  });
}
