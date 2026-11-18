import 'dart:convert';
import 'dart:io';

import 'budget.dart';
import 'fixture.dart';

bool _sameJson(Object? left, Object? right) {
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.keys.every(
          (key) => right.containsKey(key) && _sameJson(left[key], right[key]),
        );
  }
  if (left is List && right is List) {
    return left.length == right.length &&
        [for (var i = 0; i < left.length; i++) _sameJson(left[i], right[i])]
            .every((value) => value);
  }
  return left == right;
}

List<String> evaluateReadReport({
  required Map<String, dynamic> scenario,
  required Map<String, dynamic> budgets,
  required List<Map<String, dynamic>> operations,
  required List<Map<String, dynamic>> events,
  required String? completedScenario,
  required String runId,
  required Set<String> registeredSites,
}) {
  final errors = <String>[];
  if (completedScenario != scenario['id']) errors.add('シナリオの完了通知がありません');
  final definitions = array(
    scenario['operations'],
    'operations',
  ).map((raw) => object(raw, 'operation')).toList();
  final ids = definitions.map((operation) => operation['id']).toSet();
  for (final record in operations) {
    if (!ids.contains(record['id'])) errors.add('未登録の操作記録です: ${record['id']}');
  }
  for (final event in events) {
    if (event['runId'] != runId) errors.add('別実行の計測です: ${event['runId']}');
    if (!ids.contains(event['operationId'])) {
      errors.add('未登録の操作の計測です: ${event['operationId']}');
    }
    if (!registeredSites.contains(event['site'])) {
      errors.add('未登録の読み取り箇所です: ${event['site']}');
    }
  }
  for (final definition in definitions) {
    final id = definition['id'] as String;
    final logs = operations.where((entry) => entry['id'] == id).toList();
    final success = logs.where((entry) => entry['status'] == 'passed').toList();
    if (logs.length != 2 ||
        logs.first['status'] != 'started' ||
        success.length != 1 ||
        logs.last['status'] != 'passed') {
      errors.add('$id: 操作が未実行・未完了・失敗・skipまたは二重実行です');
    } else if (!_sameJson(success.single['actual'], definition['expect'])) {
      errors.add('$id: 期待結果が一致しません');
    }
    final budgetId = definition['budget'] as String;
    final budget = ReadBudget.parse(
      object(budgets[budgetId], 'budget.$budgetId'),
    );
    final reads = events.where((entry) => entry['operationId'] == id).toList();
    errors.addAll(budget.evaluate(id, reads));
    for (final site in budget.sites.entries) {
      final expectsReads = site.value.entries.any(
        (entry) => entry.key.endsWith('Starts') && entry.value > 0,
      );
      if (expectsReads &&
          !reads.any(
            (event) => event['site'] == site.key && event['phase'] == 'start',
          )) {
        errors.add('$id/${site.key}: 必須取得経路の計測がありません');
      }
    }
  }
  return errors;
}

Future<Map<String, dynamic>> _json(String path) async =>
    object(jsonDecode(await File(path).readAsString()), path);
Future<List<Map<String, dynamic>>> _lines(String path) async => [
  for (final line in await File(path).readAsLines())
    if (line.isNotEmpty) object(jsonDecode(line), path),
];

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      '使用法: dart scripts/test/firestore_reads/report.dart 結果フォルダ fixtureフォルダ',
    );
    exitCode = 64;
    return;
  }
  final [output, fixtures] = args;
  final errors = <String>[];
  var report = <String, Object?>{};
  try {
    final bundle = await _json('$output/bundle.json');
    final scenario = object(bundle['scenario'], 'scenario');
    final budgets = object(
      (await _json('$fixtures/budgets/${scenario['id']}.json'))['budgets'],
      'budgets',
    );
    final sites = array(
      (await _json('$fixtures/read_sites.json'))['sites'],
      'sites',
    ).map((entry) => object(entry, 'site')['id'] as String).toSet();
    final defines = await _json('$output/defines.json');
    final operations = await _lines('$output/operations.jsonl');
    final events = await _lines('$output/events.jsonl');
    final completed = File('$output/completed.json');
    errors.addAll(
      evaluateReadReport(
        scenario: scenario,
        budgets: budgets,
        operations: operations,
        events: events,
        completedScenario: await completed.exists()
            ? (await _json(completed.path))['scenario'] as String?
            : null,
        runId: defines['MEMORA_TEST_RUN_ID'] as String,
        registeredSites: sites,
      ),
    );
    final observed = events.map((event) => event['site']).toSet();
    report = {
      'scope': scenario['id'],
      'operations': operations,
      'events': events,
      'budgets': budgets,
      'observedReadSites': observed.toList(),
      'unexercisedReadSites': sites.difference(observed).toList()..sort(),
      'allFeaturesCovered': false,
    };
  } catch (error) {
    errors.add('結果を検証できません: $error');
  }
  report.addAll({'passed': errors.isEmpty, 'errors': errors});
  await File('$output/report.json')
      .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  for (final error in errors) {
    stderr.writeln(error);
  }
  stdout.writeln(
    errors.isEmpty ? '登録した取得経路の全操作・期待結果・読み取り予算が合格しました' : '読み取り回帰テストは不合格です',
  );
  if (errors.isNotEmpty) exitCode = 1;
}
