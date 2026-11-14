import assert from 'node:assert/strict';
const host = process.env.FIRESTORE_EMULATOR_HOST;
assert.ok(host, 'Firestore Emulator上で実行してください');
export const root = `http://${host}/v1/projects/demo-memora/databases/(default)/documents`;
const documentRoot = root.split('/v1/')[1];
export function token(uid, verified = true) {
  const enc = x => Buffer.from(JSON.stringify(x)).toString('base64url');
  return `${enc({alg:'none',typ:'JWT'})}.${enc({sub:uid,user_id:uid,aud:'demo-memora',iss:'https://securetoken.google.com/demo-memora',iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+3600,email_verified:verified,firebase:{sign_in_provider:'password'}})}.`;
}
export const raw = value => ({__value:value});
function encode(value) {
  if (value?.__value) return value.__value;
  if (value === null) return {nullValue:null};
  if (Array.isArray(value)) return {arrayValue:{values:value.map(encode)}};
  if (typeof value === 'number') return {integerValue:String(value)};
  if (typeof value === 'boolean') return {booleanValue:value};
  return {stringValue:value};
}
export const write = (path,data) => ({update:{name:`${documentRoot}/${path}`,fields:Object.fromEntries(Object.entries(data).filter(([,v])=>v!==undefined).map(([k,v])=>[k,encode(v)]))}});
export const remove = path => ({delete:`${documentRoot}/${path}`});
export async function commit(uid,writes) {
  const r = await fetch(`${root}:commit`,{method:'POST',headers:{...(uid ? {Authorization:`Bearer ${uid==='owner'?'owner':uid.includes('.')?uid:token(uid)}`} : {}),'Content-Type':'application/json'},body:JSON.stringify({writes})});
  return [r.status,await r.text()];
}
export async function expectCommit(uid,writes,status,label) {
  const [actual,body]=await commit(uid,writes);
  assert.equal(actual,status,`${label}: ${body}`);
}
export async function archivedDelete(uid, collection, id) {
  const doc=await (await fetch(`${root}/${collection}/${id}`,{headers:{Authorization:'Bearer owner'}})).json();
  return commit(uid,[{update:{name:`${documentRoot}/deleted_${collection}/${id}`,fields:doc.fields}},remove(`${collection}/${id}`)]);
}
export async function fixture(prefix, extraGroups=[]) {
  const uid=`${prefix}-uid`, member=`${prefix}-self`, group=`${prefix}-group`, invitee=`${prefix}-invitee`;
  const groups=[group,...extraGroups];
  await expectCommit('owner',[
    write(`members/${member}`,{version:1,accountId:uid,ownerId:null,groupIds:groups,managedGroupIds:groups}),
    write(`account_permissions/${uid}`,{memberId:member,memberGroupIds:groups,managedGroupIds:groups}),
    write(`groups/${group}`,{version:1,ownerId:member,name:'確認用'}),
    write(`members/${invitee}`,{version:1,accountId:null,ownerId:member,groupIds:[],managedGroupIds:[]}),
    ...groups.map(g=>write(`group_members/${g}:${member}`,{groupId:g,memberId:member,isAdministrator:false})),
  ],200,'認可済みfixture');
  return {uid,member,group,invitee};
}
