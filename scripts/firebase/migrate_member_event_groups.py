#!/usr/bin/env python3
"""すべてのメンバー別イベントに家族グループのIDを補完する。"""

import argparse
from collections import defaultdict
import json
from pathlib import Path


def make_plan(events, groups, group_id):
    entries = []
    by_key = defaultdict(list)
    for event_id, snapshot in sorted(events.items()):
        data = snapshot['data']
        if 'groupId' in data:
            status = 'completed' if data['groupId'] == group_id else 'conflict'
        else:
            status = 'ready'
        if status in ('ready', 'completed') and group_id not in groups:
            status = 'unknown-group'
        entry = {
            'id': event_id, 'groupId': group_id, 'status': status,
            'updateTime': snapshot['updateTime'],
            'before': {key: data.get(key) for key in ('groupId', 'memberId', 'year', 'memo', 'version')},
        }
        entries.append(entry)
        effective_group = data.get('groupId', group_id)
        if effective_group is not None:
            by_key[(effective_group, data['memberId'], data['year'])].append(entry)
    for duplicates in by_key.values():
        if len(duplicates) > 1:
            for entry in duplicates:
                entry['status'] = 'duplicate'
    return entries


def write_decision(entry, current):
    if current is None:
        return 'conflict'
    data = current['data']
    if 'groupId' in data:
        return 'completed' if data['groupId'] == entry['groupId'] else 'conflict'
    return 'ready' if current['updateTime'] == entry['updateTime'] else 'conflict'


def apply_entry(client, entry, conflict_errors=()):
    reference = client.collection('member_events').document(entry['id'])
    snapshot = reference.get()
    current = snapshot_record(snapshot) if snapshot.exists else None
    status = write_decision(entry, current)
    if status != 'ready':
        return status
    try:
        reference.update(
            {'groupId': entry['groupId']},
            option=client.write_option(last_update_time=snapshot.update_time),
        )
    except conflict_errors:
        return 'conflict'
    return 'applied'


def snapshot_record(snapshot):
    return {'data': snapshot.to_dict(), 'updateTime': snapshot.update_time.isoformat()}


def read_state(client):
    events = {doc.id: snapshot_record(doc) for doc in client.collection('member_events').stream()}
    groups = {doc.id for name in ('groups', 'deleted_groups')
              for doc in client.collection(name).stream()}
    return events, groups


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'JSONのキーが重複しています: {key}')
        result[key] = value
    return result


def read_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8'), object_pairs_hook=unique_object)


def valid_group_id(group_id):
    if not isinstance(group_id, str) or not group_id or '/' in group_id:
        raise ValueError('「家族」グループのIDを指定してください。')
    return group_id


def apply_plan(client, baseline, group_id, conflict_errors=()):
    originals = {entry['id']: entry for entry in baseline}
    if len(originals) != len(baseline):
        raise ValueError('確認済み計画のイベントIDが重複しています。')
    valid_group_id(group_id)
    if any(entry['groupId'] != group_id for entry in baseline):
        raise ValueError('計画の移行先が家族グループIDと一致しません。')
    events, groups = read_state(client)
    entries = make_plan(events, groups, group_id)
    for entry in entries:
        if entry['status'] in ('ready', 'completed'):
            original = originals.get(entry['id'])
            entry['status'] = write_decision(original, events.get(entry['id'])) if original else 'conflict'
    for event_id in sorted(originals.keys() - events.keys()):
        entries.append({**originals[event_id], 'status': 'conflict'})
    if any(entry['status'] not in ('ready', 'completed') for entry in entries):
        return entries, True
    for entry in entries:
        entry['status'] = apply_entry(client, originals[entry['id']], conflict_errors)
    return entries, False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['plan', 'apply'])
    parser.add_argument('--project', required=True, help='対象のFirebaseプロジェクトID')
    parser.add_argument('--group-id', help='plan: 全イベントの移行先となる「家族」グループID')
    parser.add_argument('--input', help='apply: 確認済み計画')
    parser.add_argument('--output', required=True, help='plan: 確認用計画、apply: 結果の保存先（新規ファイル）')
    args = parser.parse_args()
    if args.action == 'plan':
        if args.input or not args.group_id:
            parser.error('planには --group-id を指定してください。--input は不要です。')
        group_id = valid_group_id(args.group_id)
    else:
        if args.group_id or not args.input:
            parser.error('applyには --input を指定してください。移行先は確認済み計画を使います。')
        source = read_json(args.input)
        if source.get('projectId') != args.project or source.get('formatVersion') != 2:
            raise ValueError('確認済み計画のプロジェクトまたは形式が一致しません。')
        group_id = valid_group_id(source.get('groupId'))
        if any(entry['status'] not in ('ready', 'completed') for entry in source['entries']):
            raise ValueError('計画の移行先不明・重複・競合を解消してplanを再実行してください。')

    from google.cloud import firestore
    from google.api_core.exceptions import FailedPrecondition, NotFound

    client = firestore.Client(project=args.project)
    # 既存ファイルの上書きや、結果を保存できないままの書き込みを防ぐ。
    with Path(args.output).open('x', encoding='utf-8') as output:
        if args.action == 'plan':
            events, groups = read_state(client)
            entries = make_plan(events, groups, group_id)
            blocked = any(entry['status'] not in ('ready', 'completed') for entry in entries)
        else:
            entries, blocked = apply_plan(client, source['entries'], group_id, (FailedPrecondition, NotFound))
        json.dump({'formatVersion': 2, 'projectId': args.project, 'groupId': group_id, 'blocked': blocked, 'entries': entries},
                  output, ensure_ascii=False, indent=2)
        output.write('\n')
    counts = {status: sum(entry['status'] == status for entry in entries) for status in sorted({e['status'] for e in entries})}
    print(json.dumps(counts, ensure_ascii=False))
    return 1 if blocked or any(e['status'] == 'conflict' for e in entries) else 0


if __name__ == '__main__':
    raise SystemExit(main())
