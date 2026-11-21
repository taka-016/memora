import 'package:flutter_test/flutter_test.dart';

import '../../../scripts/firebase/remove_firestore_authorization_data.dart';

void main() {
  test('廃止した情報だけを更新時刻の条件付きで削除する', () {
    const root = 'projects/p/databases/(default)/documents';
    const updateTime = '2026-11-20T12:00:00Z';
    final writes = authorizationCleanupWrites(
      members: [
        {
          'name': '$root/members/old',
          'updateTime': updateTime,
          'fields': {
            'groupIds': {},
            'managedGroupIds': {},
            'changedGroupId': {},
            'accountId': {},
            'version': {},
          },
        },
        {
          'name': '$root/members/current',
          'updateTime': updateTime,
          'fields': {'accountId': {}, 'version': {}},
        },
      ],
      obsolete: [
        for (final collection in obsoleteAuthorizationCollections)
          {'name': '$root/$collection/id', 'updateTime': updateTime},
      ],
    );
    expect(writes, [
      {
        'update': {'name': '$root/members/old'},
        'updateMask': {
          'fieldPaths': ['groupIds', 'managedGroupIds', 'changedGroupId'],
        },
        'currentDocument': {'updateTime': updateTime},
      },
      for (final collection in [
        'account_permissions',
        'member_invitation_claims',
      ])
        {
          'delete': '$root/$collection/id',
          'currentDocument': {'updateTime': updateTime},
        },
    ]);
  });
}
