import assert from 'node:assert/strict';
const host = process.env.FIRESTORE_EMULATOR_HOST;
assert.ok(host, 'Firestore Emulator上で実行してください');
const root = `http://${host}/v1/projects/demo-memora/databases/(default)/documents`;
const name = path => `${root.split('/v1/')[1]}/${path}`;
function token(uid) {
  const enc = x => Buffer.from(JSON.stringify(x)).toString('base64url');
  return `${enc({alg:'none',typ:'JWT'})}.${enc({sub:uid,user_id:uid,aud:'demo-memora',iss:'https://securetoken.google.com/demo-memora',iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+3600,email_verified:true,firebase:{sign_in_provider:'password'}})}.`;
}
function encode(value) {
  if (value === null) return {nullValue:null};
  if (Array.isArray(value)) return {arrayValue:{values:value.map(encode)}};
  if (typeof value === 'number') return {integerValue:String(value)};
  if (typeof value === 'boolean') return {booleanValue:value};
  return {stringValue:value};
}
const write = (path,data) => ({update:{name:name(path),fields:Object.fromEntries(Object.entries(data).map(([k,v])=>[k,encode(v)]))}});
const remove = path => ({delete:name(path)});
async function commit(uid,writes) {
  const r = await fetch(`${root}:commit`,{method:'POST',headers:{Authorization:`Bearer ${uid==='owner'?'owner':token(uid)}`,'Content-Type':'application/json'},body:JSON.stringify({writes})});
  return [r.status,await r.text()];
}
async function expectCommit(uid,writes,status,label) {
  const [actual,body]=await commit(uid,writes);
  assert.equal(actual,status,`${label}: ${body}`);
}
async function get(uid,path,status,label) {
  const r=await fetch(`${root}/${path}`,{headers:{Authorization:`Bearer ${token(uid)}`}});
  assert.equal(r.status,status,`${label}: ${await r.text()}`);
}
const permissions=(memberId,memberGroupIds,managedGroupIds=[])=>({memberId,memberGroupIds,managedGroupIds});
const member=(accountId,groupIds,managedGroupIds=[])=>({version:1,accountId,ownerId:null,displayName:'本人',groupIds,managedGroupIds});
await expectCommit('owner',[
  write('members/auth-owner',member('auth-owner',['auth-g'],['auth-g'])),
  write('members/auth-member',member('auth-member',['auth-g'])),
  write('members/auth-outside',member('auth-outside',[])),
  write('account_permissions/auth-owner',permissions('auth-owner',['auth-g'],['auth-g'])),
  write('account_permissions/auth-member',permissions('auth-member',['auth-g'])),
  write('account_permissions/auth-outside',permissions('auth-outside',[])),
  write('groups/auth-g',{version:1,ownerId:'auth-owner',name:'グループ'}),
  write('group_members/auth-g:auth-owner',{groupId:'auth-g',memberId:'auth-owner',isAdministrator:false}),
  write('group_members/auth-g:auth-member',{groupId:'auth-g',memberId:'auth-member',isAdministrator:false}),
  write('calendar_events/auth-event',{version:1,groupId:'auth-g',labelType:'group',memberId:null,labelId:null}),
  write('calendar_labels/auth-label',{version:1,groupId:'auth-g',eventCount:0,name:'ラベル'}),
],200,'初期データ');
await get('auth-member','groups/auth-g',200,'所属者はグループを閲覧できる');
await get('auth-member','members/auth-owner',200,'所属者は同じグループのメンバー名を閲覧できる');
await get('auth-outside','groups/auth-g',403,'所属外はグループを閲覧できない');
await get('auth-outside','calendar_events/auth-event',403,'所属外は予定を閲覧できない');
await get('auth-outside','members/auth-owner',403,'所属外はプロフィールを閲覧できない');
await get('auth-member','account_permissions/auth-owner',403,'他人の認可文書は非公開');
await expectCommit('auth-member',[write('account_permissions/auth-member',permissions('auth-member',['auth-g'],['auth-g']))],403,'自己昇格を拒否');
await expectCommit('auth-owner',[write('account_permissions/auth-member',{...permissions('auth-member',['auth-g'],['auth-g']),changedGroupId:'auth-g'})],403,'管理者でも認可文書だけの変更は拒否');
await expectCommit('auth-member',[write('groups/auth-g',{version:2,ownerId:'auth-owner',name:'改変'})],403,'一般所属者のグループ管理を拒否');
await expectCommit('auth-member',[write('calendar_events/auth-event',{version:2,groupId:'auth-g',labelType:'group',memberId:null,labelId:null})],200,'一般所属者は予定を編集できる');
await expectCommit('auth-member',[write('calendar_labels/auth-label',{version:2,groupId:'auth-g',eventCount:0,name:'改変'})],403,'一般所属者はラベル定義を編集できない');
await expectCommit('auth-member',[write('calendar_labels/auth-label',{version:1,groupId:'auth-g',eventCount:1,name:'ラベル'})],200,'一般所属者はラベルの参照数を更新できる');
await expectCommit('auth-member',[write('calendar_events/auth-event',{version:3,groupId:'別グループ',labelType:'group',memberId:null,labelId:null})],403,'所属外への予定移動を拒否');
await expectCommit('auth-owner',[
  write('groups/auth-g',{version:2,ownerId:'auth-owner',name:'グループ'}),
  remove('group_members/auth-g:auth-member'),
  write('members/auth-member',{...member('auth-member',[]),version:2,changedGroupId:'auth-g'}),
  write('account_permissions/auth-member',{...permissions('auth-member',[]),changedGroupId:'auth-g'}),
],200,'所属と認可を同時に解除');
await get('auth-member','calendar_events/auth-event',403,'所属解除後のサーバー取得を拒否');
console.log('所属外のアクセス・不正な権限変更・解除後のアクセス拒否を確認しました');
