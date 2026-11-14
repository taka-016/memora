import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/services/device_calendar_membership_source.dart';
import '../queries/calendar/firestore_calendar_watch_query_service_test.mocks.dart';

void main() {
  test('通知設定から独立して所属文書と所属グループの削除を監視する', () async {
    final firestore = MockFirebaseFirestore();
    final collection = MockCollectionReference();
    final permission = MockDocumentReference();
    final group = MockDocumentReference();
    final permissions = StreamController<DocumentSnapshot<Map<String,dynamic>>>();
    final groups = StreamController<DocumentSnapshot<Map<String,dynamic>>>();
    addTearDown(permissions.close); addTearDown(groups.close);
    when(firestore.collection(any)).thenReturn(collection);
    when(collection.doc('uid')).thenReturn(permission);
    when(collection.doc('g')).thenReturn(group);
    when(permission.snapshots()).thenAnswer((_) => permissions.stream);
    when(group.snapshots()).thenAnswer((_) => groups.stream);
    final source = DeviceCalendarMembershipSource(firestore: firestore);
    var updates = 0;
    final subscription = source.changes('online:uid').listen((_) { updates++; });
    addTearDown(subscription.cancel);
    final membership = MockDocumentSnapshot();
    when(membership.data()).thenReturn({'memberGroupIds': ['g']});
    permissions.add(membership);
    await pumpEventQueue();
    final first = updates;
    groups.add(MockDocumentSnapshot());
    await pumpEventQueue();
    expect(updates, greaterThan(first));
    when(membership.data()).thenReturn({'memberGroupIds': []});
    permissions.add(membership);
    await pumpEventQueue();
    expect(groups.hasListener, isFalse);
    expect(updates, greaterThan(first + 1));
  });
}
