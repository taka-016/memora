import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

import 'budget.dart';
import 'fixture.dart';

const readQueryActions = <String, Map<String, String>>{
  'login': {'account': 'string'},
  'logout': {},
  'availability': {},
  'currentMember': {'accountId': 'string'},
  'group': {'groupId': 'string'},
  'calendarEvents': {'groupId': 'string', 'month': 'timestamp'},
  'calendarLabels': {'groupId': 'string'},
  'groupTimeline': {'groupId': 'string'},
  'memberTimeline': {'groupId': 'string', 'memberIds': 'strings'},
  'trips': {'groupId': 'string'},
  'trip': {'tripId': 'string'},
  'mapLocations': {'groupId': 'string'},
  'dvcContracts': {'groupId': 'string'},
  'dvcLimitedPoints': {'groupId': 'string'},
  'dvcUsages': {'groupId': 'string'},
};

void validateReadScenario(
  Map<String, dynamic> scenario,
  Map<String, dynamic> budgets,
  Set<String> registeredSites,
) {
  if (scenario['version'] != 1) invalid('未対応のシナリオ形式です');
  for (final key in ['id', 'dataset']) {
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(nonEmpty(scenario[key], key))) {
      invalid('不正な$keyです');
    }
  }
  timestamp(scenario['now']);
  data.initializeTimeZones();
  final zone = nonEmpty(scenario['timeZone'], 'timeZone');
  if (!tz.timeZoneDatabase.locations.containsKey(zone)) {
    invalid('未対応のタイムゾーンです: $zone');
  }
  if (scenario['cache'] != 'cold') invalid('この取得経路実行器はキャッシュなしだけに対応しています');
  final ids = <String>{};
  for (final raw in array(scenario['operations'], 'operations')) {
    final operation = object(raw, 'operation');
    final id = nonEmpty(operation['id'], 'operation.id');
    if (!ids.add(id)) invalid('操作IDが重複しています: $id');
    final action = nonEmpty(operation['action'], 'action');
    final schema = readQueryActions[action];
    if (schema == null) invalid('未登録の操作です: $action');
    final params = object(operation['parameters'], 'parameters');
    if (params.length != schema.length ||
        !params.keys.every(schema.containsKey)) {
      invalid('$actionの引数が一致しません');
    }
    for (final field in schema.entries) {
      switch (field.value) {
        case 'string':
          nonEmpty(params[field.key], field.key);
        case 'timestamp':
          timestamp(params[field.key]);
        case 'strings':
          final values = array(params[field.key], field.key);
          if (values.isEmpty) invalid('${field.key}には値が必要です');
          for (final value in values) {
            nonEmpty(value, field.key);
          }
      }
    }
    object(operation['expect'], 'expect');
    final budgetId = nonEmpty(operation['budget'], 'budget');
    final budget = ReadBudget.parse(
      object(budgets[budgetId], 'budget.$budgetId'),
    );
    for (final site in budget.sites.entries) {
      if (!registeredSites.contains(site.key) &&
          !(site.key == 'auth' &&
              site.value.values.every((limit) => limit == 0))) {
        invalid('予算が未登録の取得先を参照しています: ${site.key}');
      }
    }
  }
  if (ids.isEmpty) invalid('操作が登録されていません');
}
