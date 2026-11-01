import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,rmSync,writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {createPublicationRepository} from '../src/content_release_repository.js';
import {createContentRelease,contentHash} from '../src/content_release_core.js';
const source={project:'onaria',reference:'synthetic-persisted-source',kind:'original_creative',payload:{item:{id:'synthetic-persisted-source',body:'TEST_SOURCE_PRIVATE_NOT_IN_METADATA'}}};
const baseline={project:'onaria',entries:[{reference:source.reference,contentHash:contentHash(source)}]};
const open=repository=>createContentRelease({project:'onaria',repository,baseline,resolve:id=>id===source.reference?source:null,list:()=>[{reference:source.reference}]});
test('revocation survives database close/reopen and the registry stores metadata only',()=>{
 const directory=mkdtempSync(join(tmpdir(),'publication-registry-test-')),filename=join(directory,'registry.sqlite');let repo;
 try{
  repo=createPublicationRepository({filename});const flow=open(repo),d=flow.decision(source.reference);
  flow.dispatch({method:'POST',path:'/publications/'+source.reference+'/revoke',actor:{actor:'synthetic-admin',role:'admin'},body:{version:d.version,contentHash:d.contentHash}});
  assert.equal(JSON.stringify(repo.read()).includes(source.payload.item.body),false);repo.close();
  repo=createPublicationRepository({filename,requireExisting:true});assert.equal(open(repo).allows(source.reference),false);
  assert.deepEqual(open(repo).manifest().blockedIds,[source.reference]);
 }finally{repo?.close();rmSync(directory,{recursive:true,force:true});}
});
test('missing, empty and unsupported persistent registries never silently initialize in require-existing mode',()=>{
 const directory=mkdtempSync(join(tmpdir(),'publication-registry-missing-')),filename=join(directory,'registry.sqlite');
 try{
  assert.throws(()=>createPublicationRepository({filename,requireExisting:true}));
  writeFileSync(filename,'');assert.throws(()=>createPublicationRepository({filename,requireExisting:true}));
  const repo=createPublicationRepository({filename});repo.write({version:999,audit:[]});repo.close();
  assert.throws(()=>createPublicationRepository({filename,requireExisting:true}));
 }finally{rmSync(directory,{recursive:true,force:true});}
});
