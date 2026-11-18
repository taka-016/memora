import 'package:flutter_test/flutter_test.dart';
import '../../../scripts/test/firestore_reads/scenario.dart';

void main() {
  final budget = {
    'reason': 'グループ1件と所属・メンバーを取得する',
    'limits': {'getStarts': 6, 'getDocuments': 9},
    'sites': {'group': {'getStarts': 6, 'getDocuments': 9}},
  };
  final source = <String, dynamic>{
    'version': 1, 'id': 'sample', 'dataset': 'baseline',
    'now': '2026-11-15T12:00:00+09:00', 'timeZone': 'Asia/Tokyo', 'cache': 'cold',
    'operations': [
      {'id': 'open', 'action': 'group', 'parameters': {'groupId': 'g'}, 'expect': {'id': 'g', 'members': 4}, 'budget': 'group'},
    ],
  };
  test('シナリオの固定時刻・操作・引数・予算の対応を実行前に検査する', () {
    expect(() => validateReadScenario(source, {'group': budget}, {'group'}), returnsNormally);
  });
  test('未知の操作・引数不足・未知の予算と取得先・時刻の誤りを拒否する', () {
    final original = (source['operations'] as List).first as Map<String, dynamic>;
    for (final change in [
      {'action': 'unknown'}, {'parameters': {}}, {'budget': 'missing'},
      {'parameters': {'groupId': 'g', 'unknown': true}},
    ]) {
      expect(() => validateReadScenario({...source, 'operations': [{...original, ...change}]}, {'group': budget}, {'group'}), throwsFormatException);
    }
    for (final change in [
      {'timeZone': 'unknown'}, {'now': '2026-11-15'}, {'cache': 'unknown'},
      {'operations': []}, {'operations': [original, original]},
    ]) {
      expect(() => validateReadScenario({...source, ...change}, {'group': budget}, {'group'}), throwsFormatException);
    }
    expect(() => validateReadScenario(source, {'group': budget}, {}), throwsFormatException);
  });
}
