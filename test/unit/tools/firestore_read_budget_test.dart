import 'package:flutter_test/flutter_test.dart';

import '../../../scripts/test/firestore_reads/budget.dart';

void main() {
  Map<String, dynamic> budget(int starts, int documents) => {
    'reason': 'グループ1件と所属4件、メンバー4件を各1回取得する',
    'limits': {'getStarts': starts, 'getDocuments': documents},
    'sites': {
      'group': {'getStarts': starts, 'getDocuments': documents},
    },
  };
  Map<String, dynamic> event(
    String phase, {
    String site = 'group',
    int documents = 0,
  }) => {
    'runId': 'run',
    'operationId': 'open',
    'readId': '1',
    'kind': 'get',
    'site': site,
    'phase': phase,
    'origin': 'server',
    'documents': documents,
    'changes': 0,
  };
  test('上限と同じ結果は合格し超過は操作・取得先・差分付きで失敗する', () {
    final input = [
      event('start'),
      event('initial', documents: 9),
      event('end'),
    ];
    expect(ReadBudget.parse(budget(1, 9)).evaluate('open', input), isEmpty);
    expect(
      ReadBudget.parse(budget(1, 8)).evaluate('open', input).join(),
      allOf(
        contains('open'),
        contains('group'),
        contains('getDocuments'),
        contains('超過1'),
      ),
    );
  });
  test('取得エラー・未終了・未設定の取得先を0回として扱わない', () {
    final rule = ReadBudget.parse(budget(2, 10));
    for (final input in [
      [event('start')],
      [event('start'), event('end')],
      [
        event('start'),
        {...event('error'), 'error': 'permission-denied'},
      ],
      [
        event('start', site: 'unknown'),
        event('initial', site: 'unknown'),
        event('end', site: 'unknown'),
      ],
    ]) {
      expect(rule.evaluate('open', input), isNotEmpty);
    }
  });
  test('購読の再通知では全件でなく差分だけを予算と比較する', () {
    final rule = ReadBudget.parse({
      'reason': '単一購読の初回30文書、更新1文書を受信する',
      'limits': {
        'subscribeStarts': 1,
        'serverInitialDocuments': 30,
        'serverChanges': 1,
      },
      'sites': {
        'group': {
          'subscribeStarts': 1,
          'serverInitialDocuments': 30,
          'serverChanges': 1,
        },
      },
    });
    final input = [
      {...event('start'), 'kind': 'subscribe'},
      {...event('initial', documents: 30), 'kind': 'subscribe', 'changes': 30},
      {...event('changes', documents: 30), 'kind': 'subscribe', 'changes': 1},
      {...event('changes', documents: 30), 'kind': 'subscribe'},
      {...event('end'), 'kind': 'subscribe'},
    ];
    expect(rule.evaluate('open', input), isEmpty);
  });
  test('根拠なし・未知の指標・負数・取得先のない予算を拒否する', () {
    for (final input in [
      {...budget(1, 9), 'reason': ''},
      {
        ...budget(1, 9),
        'limits': {'anything': 1},
      },
      budget(-1, 9),
      {...budget(1, 9), 'sites': {}},
    ]) {
      expect(() => ReadBudget.parse(input), throwsFormatException);
    }
  });
}
