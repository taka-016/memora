import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/services/firestore_read_probe.dart';

void main() {
  test('購読の初回と変更差分を分け同一購読の再通知で全件を加算しない', () {
    final events = <Map<String, Object?>>[];
    final probe = FirestoreReadProbe(
      runId: 'run',
      operationId: () => 'month',
      emit: events.add,
    );
    final subscription = probe.start(
      site: 'calendar',
      target: 'calendar_events',
      kind: 'subscribe',
    );
    subscription.receive(
      documents: 30,
      changes: 30,
      fromCache: true,
      pendingWrites: false,
    );
    subscription.receive(
      documents: 30,
      changes: 0,
      fromCache: false,
      pendingWrites: false,
    );
    subscription.receive(
      documents: 30,
      changes: 1,
      fromCache: false,
      pendingWrites: false,
    );
    subscription.receive(
      documents: 30,
      changes: 1,
      fromCache: true,
      pendingWrites: true,
    );
    subscription.receive(
      documents: 30,
      changes: 0,
      fromCache: false,
      pendingWrites: false,
    );
    expect(events.map((e) => e['phase']), [
      'start',
      'initial',
      'initial',
      'changes',
      'initial',
      'changes',
    ]);
    expect(events.map((e) => e['origin']), [
      null,
      'cache',
      'server',
      'server',
      'local',
      'server',
    ]);
    expect(events.last['changes'], 0);
    expect(events.last['documents'], 30);
    expect(
      events.every((e) => e['operationId'] == 'month' && e['runId'] == 'run'),
      isTrue,
    );
    expect(events.map((e) => e['readId']).toSet(), hasLength(1));
  });
  test('開始時の操作IDを保持して遅延受信と失敗を記録する', () {
    final events = <Map<String, Object?>>[];
    var operation = 'startup';
    final probe = FirestoreReadProbe(
      runId: 'run',
      operationId: () => operation,
      emit: events.add,
    );
    final read = probe.start(site: 'member', target: 'members/m', kind: 'get');
    operation = 'navigate';
    read.fail('permission-denied');
    expect(events.last, containsPair('phase', 'error'));
    expect(events.last, containsPair('operationId', 'startup'));
    expect(events.last, containsPair('error', 'permission-denied'));
  });
}
