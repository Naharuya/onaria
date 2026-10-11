import test from 'node:test';
import assert from 'node:assert/strict';
import { createDeletionLab } from '../src/privacy/deletion_lab.js';
test('탈퇴 접수 즉시 신규 세션 차단, 관련 기록 삭제 및 중복 실행 방지', t => {
 const lab=createDeletionLab(); t.after(()=>lab.close());
 lab.register('old-generation'); lab.addRecord('old-generation','fixture');lab.issue('old-generation','fixture-session');
 lab.request('old-generation');lab.request('old-generation');
 assert.equal(lab.canAccess('old-generation'),false);assert.throws(()=>lab.issue('old-generation','new-session'));
 assert.equal(lab.snapshot().sessions.length,0);
 assert.equal(lab.run('old-generation'),'complete'); assert.equal(lab.run('old-generation'),'already-complete');
 assert.equal(lab.snapshot().records.length,0);
});
test('부분 실패는 rollback하고 차단/명부를 유지하며 재시도 가능', t => {
 for(const stage of ['records','account']) {
 const lab=createDeletionLab(); t.after(()=>lab.close());lab.register('old');lab.addRecord('old','fixture');lab.request('old');
 assert.throws(()=>lab.run('old',{failAt:stage}));assert.equal(lab.canAccess('old'),false);
 assert.equal(lab.snapshot().records.length,1);assert.deepEqual(lab.manifest(),['old']);
 assert.equal(lab.run('old'),'complete'); }
});
test('명부 실패 시 연결 차단, 복원 후 이전 회원 제거하고 재가입 세대 보존', t => {
 const lab=createDeletionLab(); t.after(()=>lab.close());lab.register('old');lab.addRecord('old','fixture');lab.issue('old','fixture-session');
 const backup=lab.snapshot();lab.request('old');lab.run('old');lab.register('new');lab.addRecord('new','new-fixture');
 const combined=lab.snapshot();combined.accounts.push(...backup.accounts);combined.records.push(...backup.records);combined.sessions.push(...backup.sessions);
 assert.throws(()=>lab.restore(combined,{manifest:lab.manifest()}));assert.equal(lab.connected(),false);
 assert.throws(()=>lab.restore(combined,{manifest:[],verified:true}));assert.equal(lab.connected(),false);
 lab.restore(combined,{manifest:lab.manifest(),verified:true});assert.equal(lab.connected(),true);
 assert.equal(lab.canAccess('old'),false);assert.equal(lab.canAccess('new'),true);
 assert.equal(lab.snapshot().records.length,1);assert.equal(lab.snapshot().sessions.length,0);
});
