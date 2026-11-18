import 'fixture.dart';

const readMetrics = {
  'getStarts',
  'getDocuments',
  'transactionStarts',
  'transactionDocuments',
  'subscribeStarts',
  'cacheInitialDocuments',
  'serverInitialDocuments',
  'localInitialDocuments',
  'cacheChanges',
  'serverChanges',
  'localChanges',
};

class ReadBudget {
  ReadBudget._(this.reason, this.limits, this.sites);
  final String reason;
  final Map<String, int> limits;
  final Map<String, Map<String, int>> sites;

  static ReadBudget parse(Map<String, dynamic> source) {
    final reason = nonEmpty(source['reason'], '予算の算出根拠');
    Map<String, int> metrics(Object? value) {
      final map = object(value, 'limits');
      if (map.isEmpty) invalid('予算には指標が必要です');
      return map.map((key, value) {
        if (!readMetrics.contains(key) || value is! int || value < 0) {
          invalid('未知の指標または不正な上限です: $key=$value');
        }
        return MapEntry(key, value);
      });
    }

    final sites = object(source['sites'], 'sites');
    if (sites.isEmpty) invalid('予算には取得先が必要です');
    return ReadBudget._(
      reason,
      metrics(source['limits']),
      sites.map((key, value) => MapEntry(key, metrics(value))),
    );
  }

  List<String> evaluate(String operation, List<Map<String, dynamic>> events) {
    final errors = <String>[];
    final totals = <String, int>{};
    final bySite = <String, Map<String, int>>{};
    final active = <String, String>{};
    void add(String site, String metric, int value) {
      totals[metric] = (totals[metric] ?? 0) + value;
      final metrics = bySite.putIfAbsent(site, () => {});
      metrics[metric] = (metrics[metric] ?? 0) + value;
    }

    for (final event in events) {
      final site = nonEmpty(event['site'], 'event.site');
      final id = nonEmpty(event['readId'], 'event.readId');
      if (event['operationId'] != operation) {
        errors.add('$operation: 別操作の観測が混在しています');
      }
      final kind = event['kind'];
      if (!['get', 'subscribe', 'transaction'].contains(kind)) {
        errors.add('$operation/$site: 未知の取得方式です: $kind');
        continue;
      }
      switch (event['phase']) {
        case 'start':
          if (active.containsKey(id))
            errors.add('$operation/$site: 開始が重複しています');
          active[id] = site;
          add(
            site,
            kind == 'subscribe' ? 'subscribeStarts' : '${kind}Starts',
            1,
          );
        case 'initial':
        case 'changes':
          if (!active.containsKey(id))
            errors.add('$operation/$site: 開始のない受信です');
          final documents = event['documents'];
          final changes = event['changes'];
          final origin = event['origin'];
          if (documents is! int ||
              documents < 0 ||
              changes is! int ||
              changes < 0 ||
              !['cache', 'server', 'local'].contains(origin)) {
            errors.add('$operation/$site: 不正な受信内訳です');
            continue;
          }
          if (kind != 'subscribe') {
            add(site, '${kind}Documents', documents);
          } else {
            add(
              site,
              event['phase'] == 'initial'
                  ? '${origin}InitialDocuments'
                  : '${origin}Changes',
              event['phase'] == 'initial' ? documents : changes,
            );
          }
        case 'end':
          if (active.remove(id) == null)
            errors.add('$operation/$site: 開始のない終了です');
        case 'error':
          errors.add('$operation/$site: 取得失敗 ${event['error']}');
          active.remove(id);
        default:
          errors.add('$operation/$site: 未知の観測種別です');
      }
    }
    for (final site in active.values) {
      errors.add('$operation/$site: 読み取りまたは購読が終了していません');
    }
    void compare(
      String target,
      Map<String, int> actual,
      Map<String, int> maximum,
    ) {
      for (final entry in actual.entries) {
        final max = maximum[entry.key] ?? 0;
        if (entry.value > max) {
          errors.add(
            '$operation/$target: ${entry.key}=${entry.value} 上限$max 超過${entry.value - max}',
          );
        }
      }
    }

    compare('合計', totals, limits);
    for (final entry in bySite.entries) {
      if (!sites.containsKey(entry.key)) {
        errors.add('$operation/${entry.key}: 取得先の予算が未設定です');
      } else {
        compare(entry.key, entry.value, sites[entry.key]!);
      }
    }
    return errors;
  }
}
