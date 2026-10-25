#!/usr/bin/env python3
"""アプリ停止中に、カレンダーだけを全消去して現行形式へ切り替える。"""

import argparse
import pathlib
import re
import sqlite3


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('database', type=pathlib.Path)
    parser.add_argument('--confirm-calendar-delete', action='store_true', required=True,
                        help='予定・個別回・任意ラベルの全消去に同意する')
    args = parser.parse_args()
    schema = (pathlib.Path(__file__).resolve().parents[2]
              / 'lib/infrastructure/database/offline_schema.drift').read_text()
    statements = re.findall(r'CREATE (?:TABLE|INDEX) calendar_.*?;', schema, re.S)
    with sqlite3.connect(args.database.resolve().as_uri() + '?mode=rw', uri=True) as db:
        version = db.execute('PRAGMA user_version').fetchone()[0]
        if version not in (8, 9):
            raise ValueError(f'切替対象外のDBバージョンです: {version}')
        db.execute('PRAGMA foreign_keys = ON')
        db.execute('BEGIN IMMEDIATE')
        for table in ('calendar_event_overrides', 'calendar_events', 'calendar_labels'):
            db.execute(f'DROP TABLE {table}')
        if version == 8:
            for table, color in [('groups', '#4CAF50'), ('deleted_groups', '#4CAF50'),
                                 ('group_members', '#2196F3')]:
                constraint = " CHECK (length(color) = 7 AND substr(color, 1, 1) = '#' AND substr(color, 2) NOT GLOB '*[^0-9a-fA-F]*')" if table != 'deleted_groups' else ''
                db.execute(f'ALTER TABLE "{table}" ADD COLUMN color TEXT NOT NULL DEFAULT \'{color}\'{constraint}')
        for statement in statements:
            db.execute(re.sub(r'\) AS Sqlite\w+Row;', ');', statement))
        db.execute('PRAGMA user_version = 9')
        db.commit()
        db.execute('PRAGMA wal_checkpoint(TRUNCATE)')
    print('カレンダーの予定・個別回・任意ラベルを全消去しました。グループ・所属・年表は保持しています。')


if __name__ == '__main__':
    main()
