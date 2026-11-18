import 'package:flutter_test/flutter_test.dart';
import '../../../scripts/test/firestore_reads/report.dart';

void main() {
  final scenario = <String, dynamic>{
    'id': 'sample',
    'operations': [
      {'id': 'open', 'budget': 'open', 'expect': {'count': 1}},
    ],
  };
  final budgets = <String, dynamic>{
    'open': {
      'reason': 'グループ文書1件を1回取得する',
      'limits': {'getStarts': 1, 'getDocuments': 1},
      'sites': {'groups': {'getStarts': 1, 'getDocuments': 1}},
    },
  };
  final records = <Map<String, dynamic>>[
    {'id': 'open', 'status': 'started'},
    {'id': 'open', 'status': 'passed', 'actual': {'count': 1}},
  ];
  final events = <Map<String, dynamic>>[
    for (final phase in ['start', 'initial', 'end'])
      {'runId': 'run', 'operationId': 'open', 'readId': 'read',
       'site': 'groups', 'kind': 'get', 'phase': phase,
       'origin': 'server', 'documents': 1, 'changes': 0},
  ];
  List<String> judge({List<Map<String, dynamic>>? logs,
    List<Map<String, dynamic>>? reads, String? completed = 'sample'}) =>
      evaluateReadReport(scenario: scenario, budgets: budgets,
        operations: logs ?? records, events: reads ?? events,
        completedScenario: completed, runId: 'run', registeredSites: {'groups'});

  test('実行完了・期待結果・計測・予算が揃った操作だけを合格にする', () {
    expect(judge(), isEmpty);
  });
  test('未実行・skip・二重実行・未完了・期待結果の不一致を成功にしない', () {
    for (final logs in [
      <Map<String, dynamic>>[],
      [{'id': 'open', 'status': 'skipped'}],
      [...records, ...records],
      [records.first],
      [records.first, {'id': 'open', 'status': 'passed', 'actual': {'count': 0}}],
    ]) {
      expect(judge(logs: logs), isNotEmpty);
    }
    expect(judge(completed: null), isNotEmpty);
  });
  test('取得経路の計測欠落と別実行・別操作・未登録の計測を拒否する', () {
    for (final reads in [
      <Map<String, dynamic>>[],
      [for (final event in events) {...event, 'runId': 'other'}],
      [for (final event in events) {...event, 'operationId': 'unknown'}],
      [for (final event in events) {...event, 'site': 'unregistered'}],
    ]) {
      expect(judge(reads: reads), isNotEmpty);
    }
  });
}
