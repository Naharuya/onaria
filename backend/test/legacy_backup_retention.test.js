import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {pruneLegacyBackups} from '../scripts/legacy_backup_retention.js';
test('legacy sweep removes expired ONARIA rollback directories without following nested symlinks',t=>{
 const temp=fs.mkdtempSync(path.join(os.tmpdir(),'onaria-legacy-'));
 t.after(()=>fs.rmSync(temp,{recursive:true,force:true}));
 const root=path.join(temp,'onaria-backups');fs.mkdirSync(root);
 const outside=path.join(temp,'keep');fs.mkdirSync(outside);fs.writeFileSync(path.join(outside,'keep.txt'),'keep');
 const old=path.join(root,'deploy-20260901-000000-abc');fs.mkdirSync(old);
 fs.symlinkSync(outside,path.join(old,'link'));fs.utimesSync(old,new Date('2026-09-01T00:00:00Z'),new Date('2026-09-01T00:00:00Z'));
 const recent=path.join(root,'social-identity-build20-20261010-000000');fs.mkdirSync(recent);
 const now=new Date('2026-10-11T00:00:00Z');
 assert.equal(pruneLegacyBackups({root,now}).candidates,1);assert.ok(fs.existsSync(old));
 assert.equal(pruneLegacyBackups({root,now,apply:true}).removed,1);
 assert.ok(fs.existsSync(path.join(outside,'keep.txt')));assert.ok(fs.existsSync(recent));
});
test('legacy sweep fails closed on unknown root entries',t=>{
 const temp=fs.mkdtempSync(path.join(os.tmpdir(),'onaria-legacy-invalid-'));
 t.after(()=>fs.rmSync(temp,{recursive:true,force:true}));
 const root=path.join(temp,'onaria-backups');fs.mkdirSync(root);fs.mkdirSync(path.join(root,'unknown'));
 assert.throws(()=>pruneLegacyBackups({root,apply:true}),/Unmanaged/);
});
