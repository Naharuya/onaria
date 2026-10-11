import test from 'node:test';
import assert from 'node:assert/strict';
import { planAccountMerge } from '../src/account_merge_plan.js';
const fixture = () => ({
 members: [{id:4},{id:5},{id:6},{id:9}],
 identities: [
  {memberId:4,provider:'google',providerUserId:'fixture-google'},
  {memberId:4,provider:'kakao',providerUserId:'fixture-kakao'},
  {memberId:5,provider:'apple',providerUserId:'fixture-apple'},
  {memberId:6,provider:'naver',providerUserId:'fixture-naver'},
  {memberId:9,provider:'naver',providerUserId:'other-fixture'}
 ], targetId:4,sourceIds:[5,6]
});
test('plan preserves all owners, excludes outsiders and cannot authorize execution',()=>{
 const f=fixture(), before=JSON.stringify(f), p=planAccountMerge(f);
 assert.equal(JSON.stringify(f),before);
 assert.equal(p.status,'PLAN_ONLY_NOT_AUTHORIZED');
 assert.deepEqual(p.preservedRecordOwnerIds,[4,5,6]);
 assert.deepEqual(p.requiredProofMemberIds,[4,5,6]);
 assert.equal(p.sourceMemberDeletion,false);
 assert.equal(p.guestAndUnclaimedRecords,'EXCLUDED');
 assert(!JSON.stringify(p).includes('fixture-'));
});
test('different accounts at the same provider cannot silently overwrite each other',()=>{
 const f=fixture(); f.sourceIds=[6,9];
 assert.throws(()=>planAccountMerge(f),/SAME_PROVIDER_ACCOUNT_CONFLICT/);
});
test('unknown, repeated or self sources are rejected',()=>{
 for(const ids of [[4],[5,5],[8],[],[-1]]) assert.throws(()=>planAccountMerge({...fixture(),sourceIds:ids}));
});
test('orphan and duplicate ownership snapshots are rejected',()=>{
 const f=fixture();f.identities.push({...f.identities[0],memberId:9});
 assert.throws(()=>planAccountMerge(f),/DUPLICATE_IDENTITY_SNAPSHOT/);
 const g=fixture();g.identities[0].memberId=88;
 assert.throws(()=>planAccountMerge(g),/INVALID_IDENTITY_SNAPSHOT/);
});
test('a member without an authentication identity cannot be absorbed',()=>{
 const f=fixture();f.identities=f.identities.filter(i=>i.memberId!==5);
 assert.throws(()=>planAccountMerge(f),/MEMBER_WITHOUT_IDENTITY/);
});
test('duplicate member ids and malformed identities are rejected',()=>{
 const f=fixture();f.members.push({id:4});
 assert.throws(()=>planAccountMerge(f),/INVALID_MEMBER_SNAPSHOT/);
 const g=fixture();g.identities[0].providerUserId='';
 assert.throws(()=>planAccountMerge(g),/INVALID_IDENTITY_SNAPSHOT/);
});
