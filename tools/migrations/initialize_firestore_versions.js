#!/usr/bin/env node

const TARGETS = ['members', 'member_invitations', 'group_events', 'member_events',
  'trip_entries', 'groups', 'calendar_events', 'dvc_point_contracts', 'calendar_labels'];
const DVC_CHILDREN = ['dvc_point_usages', 'dvc_limited_points'];

function createClient({ project, database = '(default)', host, pageSize = 300 }) {
  if (!project || !/^[a-z0-9-]+$/.test(project)) throw new Error('--projectを明示してください');
  if (host && !project.startsWith('demo-')) throw new Error('Emulatorはdemo-プロジェクトだけを使用してください');
  const base = host ? `http://${host}/v1` : 'https://firestore.googleapis.com/v1';
  const root = `projects/${project}/databases/${encodeURIComponent(database)}/documents`;
  const credential = host ? null : require('firebase-admin/app').applicationDefault();
  async function request(path, method = 'GET', body) {
    const bearer = host ? 'owner' : (await credential.getAccessToken()).access_token;
    const response = await fetch(`${base}/${path}`, {
      method, headers: { Authorization: `Bearer ${bearer}`, 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(60000),
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
    if (!response.ok) throw new Error(`${method} ${path}: ${response.status} ${await response.text()}`);
    return response.json();
  }
  return {
    async list(collection) {
      const documents = [];
      let token;
      do {
        const query = new URLSearchParams({ pageSize: String(pageSize) });
        if (token) query.set('pageToken', token);
        const page = await request(`${root}/${collection}?${query}`);
        documents.push(...(page.documents || []));
        token = page.nextPageToken;
      } while (token);
      return documents;
    },
    async initialize(doc) {
      await request(`${root}:commit`, 'POST', { writes: [{
        update: { name: doc.name, fields: { version: { integerValue: '1' } } },
        updateMask: { fieldPaths: ['version'] },
        currentDocument: { updateTime: doc.updateTime },
      }] });
    },
  };
}

function validVersion(value) {
  return typeof value?.integerValue === 'string'
    && /^\d+$/.test(value.integerValue) && BigInt(value.integerValue) >= 1n;
}

async function inspect(client, log) {
  const missing = [];
  const invalid = [];
  const all = new Map();
  let total = 0;
  for (const collection of TARGETS) {
    const docs = await client.list(collection);
    all.set(collection, docs);
    let count = 0;
    let bad = 0;
    for (const doc of docs) {
      const value = doc.fields?.version;
      if (value === undefined) {
        missing.push(doc);
        count++;
      } else if (!validVersion(value)) {
        invalid.push({ name: doc.name, reason: 'version不正', value });
        bad++;
      }
    }
    total += docs.length;
    log({ collection, total: docs.length, missing: count, invalid: bad });
  }
  const contracts = new Map(all.get('dvc_point_contracts').map(doc => [doc.name.split('/').at(-1), doc]));
  for (const doc of contracts.values()) {
    if (!doc.fields?.groupId?.stringValue) invalid.push({ name: doc.name, reason: 'DVC契約のgroupId未設定' });
  }
  for (const collection of DVC_CHILDREN) {
    const children = await client.list(collection);
    log({ collection, total: children.length });
    for (const doc of children) {
      const contract = contracts.get(doc.fields?.contractId?.stringValue);
      const group = doc.fields?.groupId?.stringValue;
      if (!contract || !group || group !== contract.fields?.groupId?.stringValue) {
        invalid.push({ name: doc.name, reason: 'DVC契約と子の紐付け未完了' });
      }
    }
  }
  for (const problem of invalid) log({ invalidDocument: problem });
  return { total, missing, invalid };
}

async function migrate(client, { apply = false, log = console.log } = {}) {
  let updated = 0;
  try {
    let result = await inspect(client, log);
    if (apply && result.invalid.length === 0) {
      for (const doc of result.missing) {
        await client.initialize(doc);
        updated++;
        log({ initialized: doc.name, updated });
      }
      result = await inspect(client, log);
    }
    const report = {
      total: result.total, missing: result.missing.length, invalid: result.invalid.length,
      updated, complete: result.missing.length === 0 && result.invalid.length === 0,
    };
    log(report);
    return report;
  } catch (error) {
    log({ updated, complete: false, error: error.message });
    throw error;
  }
}

async function main() {
  const args = process.argv.slice(2);
  const options = { host: process.env.FIRESTORE_EMULATOR_HOST };
  let apply = false;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--apply') apply = true;
    else if (['--project', '--database'].includes(args[i]) && args[i + 1] && !args[i + 1].startsWith('--')) {
      options[args[i].slice(2)] = args[++i];
    } else throw new Error('使用方法: node initialize_firestore_versions.js --project ID [--database ID] [--apply]');
  }
  const report = await migrate(createClient(options), { apply, log: value => console.log(JSON.stringify(value)) });
  if (!report.complete) process.exitCode = 1;
}

if (require.main === module) main().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});
module.exports = { createClient, migrate };
