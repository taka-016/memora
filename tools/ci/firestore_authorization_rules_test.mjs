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
await commit('owner',['group_events','member_events','trip_entries','dvc_point_contracts'].map(table=>remove(`${table}/auth-record`)));
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
// 所属・認可のいずれか片方だけの変更も拒否する。
await expectCommit('auth-owner',[
  write('groups/auth-g',{version:3,ownerId:'auth-owner',name:'グループ'}),
  write('group_members/auth-g:auth-member',{groupId:'auth-g',memberId:'auth-member',isAdministrator:true}),
],403,'所属側だけの追加と管理者変更を拒否');
await expectCommit('auth-owner',[
  write('groups/auth-g',{version:3,ownerId:'auth-owner',name:'グループ'}),
  write('group_members/auth-g:auth-member',{groupId:'auth-g',memberId:'auth-member',isAdministrator:true}),
  write('members/auth-member',{...member('auth-member',['auth-g'],['auth-g']),version:3,changedGroupId:'auth-g'}),
  write('account_permissions/auth-member',{...permissions('auth-member',['auth-g'],['auth-g']),changedGroupId:'auth-g'}),
],200,'所属と役割と認可の同時追加を許可');
for (const table of ['group_events','member_events','trip_entries','dvc_point_contracts']) {
  await expectCommit('auth-member',[write(`${table}/auth-record`,{version:1,groupId:'auth-g',memberId:'auth-member'})],200,`${table}は所属メンバーが作成できる`);
  await get('auth-outside',`${table}/auth-record`,403,`${table}の所属外取得を拒否`);
}
for (const [table,key,id] of [['locations','tripId','auth-record'],['tasks','tripId','auth-record'],['itinerary_items','tripId','auth-record'],['dvc_limited_points','contractId','auth-record'],['dvc_point_usages','contractId','auth-record'],['calendar_event_overrides','eventId','auth-event']]) {
  await expectCommit('owner',[write(`${table}/auth-child`,{[key]:id,groupId:'auth-g',isCancelled:true})],200,'子の初期データ');
  await get('auth-outside',`${table}/auth-child`,403,`${table}の所属外取得を拒否`);
}
await expectCommit('owner',[remove('members/auth-new'),remove('account_permissions/auth-new')],200,'本人登録データを初期化');
await expectCommit('auth-outside',[write('members/auth-new',member('auth-outside',[]))],403,'認可文書なしの本人登録を拒否');
await expectCommit('auth-new',[
  write('members/auth-new',member('auth-new',[])),
  write('account_permissions/auth-new',permissions('auth-new',[])),
],200,'本人と空の認可文書を同時登録できる');
await expectCommit('auth-new',[write('members/auth-new',{...member('auth-new',['auth-g']),version:2})],403,'プロフィール編集からの所属偽装を拒否');
for(const table of ['groups','calendar_events','members','account_permissions']) {
  const r=await fetch(`${root}:runQuery`,{method:'POST',headers:{Authorization:`Bearer ${token('auth-outside')}`,'Content-Type':'application/json'},body:JSON.stringify({structuredQuery:{from:[{collectionId:table}]}})});
  assert.equal(r.status,403,`${table}の無条件一覧を拒否: ${await r.text()}`);
}
await expectCommit('owner',[
  remove('account_permissions/auth-joiner'),remove('member_invitation_claims/auth-joiner'),
  write('members/auth-invitee',{...member(null,['auth-g']),ownerId:'auth-owner'}),
  write('member_invitations/auth-secret',{version:1,inviteeId:'auth-invitee',inviterId:'auth-owner',invitationCode:'auth-secret'}),
],200,'招待対象を準備');
await get('auth-joiner','members/auth-invitee',403,'招待コードを持たない利用者にはプロフィールを公開しない');
await get('auth-joiner','member_invitations/auth-secret',200,'招待コードを知る利用者は有効な招待を取得できる');
await expectCommit('auth-joiner',[write('member_invitation_claims/auth-joiner',{code:'auth-secret'})],200,'有効な招待コードを本人の受理処理へ紐付ける');
await get('auth-joiner','members/auth-invitee',200,'有効な招待を持つ本人だけが対象プロフィールを取得できる');
await expectCommit('auth-joiner',[
  write('members/auth-invitee',{...member('auth-joiner',['auth-g']),ownerId:'auth-owner',version:2}),
  write('account_permissions/auth-joiner',permissions('auth-invitee',['auth-g'])),
  remove('member_invitations/auth-secret'),remove('member_invitation_claims/auth-joiner'),
],200,'招待受理では紐付けと既存所属の認可と招待削除を同時保存する');
await get('auth-joiner','groups/auth-g',200,'招待受理後は既存所属の記録を閲覧できる');
await expectCommit('owner',[
  write('deleted_groups/auth-archived',{version:1,ownerId:'old'}),
  write('deleted_members/auth-archived-member',{version:1}),
  remove('groups/auth-archived'),remove('members/auth-archived-member'),
],200,'退避済み親を準備');
await expectCommit('auth-owner',[
  write('groups/auth-archived',{version:1,ownerId:'auth-owner'}),
  write('group_members/auth-archived:auth-owner',{groupId:'auth-archived',memberId:'auth-owner',isAdministrator:false}),
  write('members/auth-owner',{...member('auth-owner',['auth-g','auth-archived'],['auth-g','auth-archived']),version:2,changedGroupId:'auth-archived'}),
  write('account_permissions/auth-owner',{...permissions('auth-owner',['auth-g','auth-archived'],['auth-g','auth-archived']),changedGroupId:'auth-archived'}),
],403,'退避済みグループIDの再利用による旧記録へのアクセスを拒否');
await expectCommit('auth-unregistered',[
  write('members/auth-archived-member',member('auth-unregistered',[])),
  write('account_permissions/auth-unregistered',permissions('auth-archived-member',[])),
],403,'退避済みメンバーIDの再利用を拒否');
await expectCommit('owner',[remove('groups/auth-created'),remove('group_members/auth-created:auth-owner'),remove('group_members/auth-created:auth-invitee')],200,'新規グループを初期化');
await expectCommit('auth-owner',[
  write('groups/auth-created',{version:1,ownerId:'auth-owner'}),
  write('group_members/auth-created:auth-owner',{groupId:'auth-created',memberId:'auth-owner',isAdministrator:false}),
  write('group_members/auth-created:auth-invitee',{groupId:'auth-created',memberId:'auth-invitee',isAdministrator:false}),
  write('members/auth-owner',{...member('auth-owner',['auth-g','auth-created'],['auth-g','auth-created']),version:2,changedGroupId:'auth-created'}),
  write('account_permissions/auth-owner',{...permissions('auth-owner',['auth-g','auth-created'],['auth-g','auth-created']),changedGroupId:'auth-created'}),
  write('members/auth-invitee',{...member('auth-joiner',['auth-g','auth-created']),ownerId:'auth-owner',version:3,changedGroupId:'auth-created'}),
  write('account_permissions/auth-joiner',{...permissions('auth-invitee',['auth-g','auth-created']),changedGroupId:'auth-created'}),
],200,'所有者以外のメンバーを含むグループを作成できる');
await expectCommit('owner',[remove('trip_entries/auth-parent'),remove('tasks/auth-new-child')],200,'新規旅行を初期化');
await expectCommit('auth-owner',[
  write('trip_entries/auth-parent',{groupId:'auth-g',version:1}),
  write('tasks/auth-new-child',{tripId:'auth-parent',name:'準備'}),
],200,'旅行とタスクを同時作成できる');
