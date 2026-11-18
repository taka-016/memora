import 'dart:convert';
import 'dart:io';

import 'scenario.dart';
import 'fixture.dart';

Future<Map<String, dynamic>> readJson(String path) async =>
    object(jsonDecode(await File(path).readAsString()), path);

Future<void> main(List<String> args) async {
  final validateOnly = args.length == 5 && args.last == '--validate';
  if (validateOnly) args = args.sublist(0, 4);
  if (args.length != 4) {
    stderr.writeln(
      '使用法: dart scripts/test/firestore_reads/host.dart fixtureフォルダ scenarioID 出力フォルダ 実行ID',
    );
    exitCode = 64;
    return;
  }
  final [directory, scenarioId, output, runId] = args;
  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(scenarioId)) invalid('不正なシナリオIDです');
  final scenario = await readJson('$directory/scenarios/$scenarioId.json');
  if (scenario['version'] != 1 || scenario['id'] != scenarioId) {
    invalid('シナリオの形式かIDが不正です');
  }
  final datasetId = nonEmpty(scenario['dataset'], 'dataset');
  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(datasetId)) invalid('不正なデータセットIDです');
  final dataset = await readJson('$directory/datasets/$datasetId.json');
  ReadFixture.parse(dataset);
  final rules = await readJson('$directory/budgets/$scenarioId.json');
  if (rules['version'] != 1) invalid('未対応の予算形式です');
  final budgets = object(rules['budgets'], 'budgets');
  final registry = await readJson('$directory/read_sites.json');
  final registeredSites = array(
    registry['sites'],
    'sites',
  ).map((entry) => object(entry, 'site')['id'] as String).toSet();
  validateReadScenario(scenario, budgets, registeredSites);
  final ids = array(
    scenario['operations'],
    'operations',
  ).map((entry) => object(entry, 'operation')['id'] as String).toSet();
  if (validateOnly) return;
  final bundle = {
    'projectId': readRegressionProjectId,
    'scenario': scenario,
    'dataset': dataset,
  };
  await Directory(output).create(recursive: true);
  await File('$output/bundle.json').writeAsString(jsonEncode(bundle));
  await File('$output/defines.json').writeAsString(
    jsonEncode({
      'MEMORA_APP_MODE': 'online',
      'MEMORA_FIRESTORE_READ_REGRESSION': 'true',
      'MEMORA_TEST_RUN_ID': runId,
      'MEMORA_TEST_NOW': scenario['now'],
      'MEMORA_TEST_TIME_ZONE': scenario['timeZone'],
    }),
  );
  final events = File('$output/events.jsonl');
  final operations = File('$output/operations.jsonl');
  await events.writeAsString('');
  await operations.writeAsString('');
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8765);
  stdout.writeln('ready');
  await for (final request in server) {
    try {
      if (request.uri.path == '/health') {
        request.response.write(jsonEncode({'runId': runId}));
      } else if (request.headers.value('X-Memora-Run') != runId) {
        request.response.statusCode = 403;
        request.response.write('実行IDが一致しません');
      } else if (request.method == 'GET' && request.uri.path == '/bundle') {
        request.response.write(jsonEncode(bundle));
      } else if (request.method == 'POST') {
        final body = object(
          jsonDecode(await utf8.decoder.bind(request).join()),
          'request',
        );
        switch (request.uri.path) {
          case '/event':
            if (body['runId'] != runId) invalid('観測の実行IDが不正です');
            await events.writeAsString(
              '${jsonEncode(body)}\n',
              mode: FileMode.append,
              flush: true,
            );
          case '/begin':
            if (!ids.contains(body['id'])) invalid('未登録の操作です');
            await operations.writeAsString(
              '${jsonEncode({...body, 'status': 'started'})}\n',
              mode: FileMode.append,
              flush: true,
            );
          case '/operation':
            if (!ids.contains(body['id'])) invalid('未登録の操作です');
            await operations.writeAsString(
              '${jsonEncode(body)}\n',
              mode: FileMode.append,
              flush: true,
            );
          case '/completed':
            await File('$output/completed.json')
                .writeAsString(jsonEncode(body), flush: true);
          default:
            request.response.statusCode = 404;
        }
        request.response.write('{}');
      } else {
        request.response.statusCode = 404;
      }
    } catch (error, stack) {
      request.response.statusCode = 500;
      request.response.write(jsonEncode({'error': error.toString()}));
      stderr.writeln('$error\n$stack');
    } finally {
      await request.response.close();
    }
  }
}
