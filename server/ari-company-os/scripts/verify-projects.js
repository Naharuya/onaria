import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
import YAML from 'yaml';
import {loadProfile} from '../src/profile.js';
import {VerificationRunner} from '../src/verification_runner.js';
const projects=YAML.parse(fs.readFileSync('config/projects.yaml','utf8')).projects;
const reports=[];
for(const p of projects){
 const profile=loadProfile(p.dir),branch=execFileSync('git',['branch','--show-current'],{cwd:p.dir,encoding:'utf8'}).trim();
 const report=await new VerificationRunner().verify({project:p.id,branch,cwd:p.dir,checks:profile.checks,build:profile.build,coverage:profile.coverage});
 report.commit=execFileSync('git',['rev-parse','HEAD'],{cwd:p.dir,encoding:'utf8'}).trim();reports.push(report);console.log(JSON.stringify(report));
 fs.writeFileSync(process.env.ARI_PROJECT_REPORT??'/Users/server/ari-server/runtime/ari-company-os/evidence/project-verification.json',JSON.stringify(reports,null,2)+'\n');
}
