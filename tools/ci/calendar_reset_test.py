import pathlib
import sqlite3
import subprocess
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[2] / 'scripts/calendar/reset_offline_calendar.py'


class CalendarResetTest(unittest.TestCase):
    def test_カレンダーだけを消去してグループ所属と年表を保持する(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / 'memora.sqlite'
            with sqlite3.connect(path) as db:
                db.executescript('''
                    PRAGMA user_version = 8;
                    CREATE TABLE groups (id TEXT PRIMARY KEY, owner_id TEXT, name TEXT, memo TEXT);
                    CREATE TABLE deleted_groups (id TEXT PRIMARY KEY, owner_id TEXT, name TEXT, memo TEXT);
                    CREATE TABLE group_members (group_id TEXT, member_id TEXT, is_administrator INTEGER, order_index INTEGER);
                    CREATE TABLE members (id TEXT PRIMARY KEY, display_name TEXT);
                    CREATE TABLE member_events (id TEXT PRIMARY KEY, memo TEXT);
                    CREATE TABLE calendar_events (id TEXT PRIMARY KEY);
                    CREATE TABLE calendar_event_overrides (event_id TEXT);
                    CREATE TABLE calendar_labels (id TEXT PRIMARY KEY);
                    INSERT INTO groups VALUES ('g', 'm', '家族', 'メモ');
                    INSERT INTO members VALUES ('m', '太郎');
                    INSERT INTO group_members VALUES ('g', 'm', 1, 0);
                    INSERT INTO member_events VALUES ('年表', '残す');
                    INSERT INTO calendar_events VALUES ('予定');
                    INSERT INTO calendar_event_overrides VALUES ('予定');
                    INSERT INTO calendar_labels VALUES ('ラベル');
                ''')
            refused = subprocess.run(['python3', str(SCRIPT), str(path)], capture_output=True)
            self.assertNotEqual(refused.returncode, 0)
            with sqlite3.connect(path) as db:
                self.assertEqual(db.execute('SELECT count(*) FROM calendar_events').fetchone()[0], 1)
            result = subprocess.run(['python3', str(SCRIPT), str(path), '--confirm-calendar-delete'], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            with sqlite3.connect(path) as db:
                self.assertEqual(db.execute('PRAGMA user_version').fetchone()[0], 9)
                for table in ['calendar_events', 'calendar_event_overrides', 'calendar_labels']:
                    self.assertEqual(db.execute(f'SELECT count(*) FROM {table}').fetchone()[0], 0)
                self.assertEqual(db.execute('SELECT name, color FROM groups').fetchone(), ('家族', '#4CAF50'))
                self.assertEqual(db.execute('SELECT member_id, color FROM group_members').fetchone(), ('m', '#2196F3'))
                self.assertEqual(db.execute('SELECT memo FROM member_events').fetchone()[0], '残す')
                self.assertEqual(db.execute('SELECT display_name FROM members').fetchone()[0], '太郎')


if __name__ == '__main__':
    unittest.main()
