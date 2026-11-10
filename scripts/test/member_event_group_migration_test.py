import importlib.util
from pathlib import Path
import unittest
from unittest.mock import Mock

spec = importlib.util.spec_from_file_location(
    'migration', Path(__file__).parents[1] / 'firebase' / 'migrate_member_event_groups.py')
migration = importlib.util.module_from_spec(spec)
spec.loader.exec_module(migration)


def event(group_id=None, stamp='取得時点', memo='記録'):
    data = {'memberId': 'm', 'year': 2026, 'memo': memo, 'version': 3}
    if group_id is not None:
        data['groupId'] = group_id
    return {'data': data, 'updateTime': stamp}


class メンバーイベント移行テスト(unittest.TestCase):
    def test_未指定と不明な移行先と存在しないイベントを報告する(self):
        plan = migration.make_plan({'a': event(), 'b': event()}, {'g'}, {'b': '不明', 'missing': 'g'})
        self.assertEqual([e['status'] for e in plan], ['unmapped', 'unknown-group', 'unknown-event'])

    def test_既存記録と移行予定の重複を両方報告する(self):
        plan = migration.make_plan({'a': event(), 'b': event('g')}, {'g'}, {'a': 'g'})
        self.assertEqual([e['status'] for e in plan], ['duplicate', 'duplicate'])

    def test_別グループなら同じメンバーと年を保持できる(self):
        plan = migration.make_plan({'a': event(), 'b': event('other')}, {'g', 'other'}, {'a': 'g'})
        self.assertEqual([e['status'] for e in plan], ['ready', 'completed'])
        self.assertEqual(plan[0]['before']['memo'], '記録')

    def test_既存グループは補完済みと競合を区別する(self):
        for group_id, status in [('g', 'completed'), ('other', 'conflict')]:
            plan = migration.make_plan({'a': event(group_id)}, {'g', 'other'}, {'a': 'g'})
            self.assertEqual(plan[0]['status'], status)

    def test_確認後の変更と削除は補完しない(self):
        plan = migration.make_plan({'a': event()}, {'g'}, {'a': 'g'})
        for current in [event(stamp='変更後'), None, event('other')]:
            self.assertEqual(migration.write_decision(plan[0], current), 'conflict')

    def test_再実行は補完済みを報告する(self):
        plan = migration.make_plan({'a': event()}, {'g'}, {'a': 'g'})
        self.assertEqual(migration.write_decision(plan[0], event('g', stamp='補完後')), 'completed')

    def test_IDと内容を保持しグループだけを取得時点の条件付きで更新する(self):
        client = Mock()
        snapshot = client.collection.return_value.document.return_value.get.return_value
        snapshot.exists = True
        snapshot.to_dict.return_value = event()['data']
        snapshot.update_time.isoformat.return_value = '取得時点'
        plan = migration.make_plan({'a': event()}, {'g'}, {'a': 'g'})
        result = migration.apply_entry(client, plan[0])
        self.assertEqual(result, 'applied')
        client.collection.assert_called_once_with('member_events')
        client.collection.return_value.document.assert_called_once_with('a')
        client.collection.return_value.document.return_value.update.assert_called_once_with(
            {'groupId': 'g'}, option=client.write_option.return_value)
        client.write_option.assert_called_once_with(last_update_time=snapshot.update_time)

    def test_条件付き書き込みの失敗は競合として報告する(self):
        client = Mock()
        snapshot = client.collection.return_value.document.return_value.get.return_value
        snapshot.exists = True
        snapshot.to_dict.return_value = event()['data']
        snapshot.update_time.isoformat.return_value = '取得時点'
        client.collection.return_value.document.return_value.update.side_effect = migration.MigrationConflict('変更済み')
        plan = migration.make_plan({'a': event()}, {'g'}, {'a': 'g'})
        self.assertEqual(migration.apply_entry(client, plan[0]), 'conflict')


if __name__ == '__main__':
    unittest.main()
