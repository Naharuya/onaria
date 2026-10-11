from pathlib import Path
import sys,os,json,hashlib,zipfile,subprocess,shutil,pwd,grp,time
backend=Path('/opt/onaria/backend')
def run(args):
 r=subprocess.run(args,capture_output=True,text=True)
 if r.returncode:raise RuntimeError('Command failed: '+args[0]+' '+str(r.returncode))
 return r
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
archive=Path(sys.argv[1]).resolve(strict=True)
expected=Path(str(archive)+'.sha256').read_text().strip()
if digest(archive)!=expected:raise RuntimeError('Artifact checksum mismatch')
if os.geteuid()!=0:raise RuntimeError('Root required for approved deployment')
with zipfile.ZipFile(archive) as z:
 manifest=json.loads(z.read('release-manifest.json'))
 names=set(z.namelist())
 if names!=set(manifest['files'])|{'release-manifest.json'}:raise RuntimeError('Unexpected archive members')
 for name,sha in manifest['files'].items():
  p=Path(name)
  if p.is_absolute() or '..' in p.parts or hashlib.sha256(z.read(name)).hexdigest()!=sha:raise RuntimeError('Artifact member verification failed')
 baseline=json.loads(z.read('ops/retention-release-baseline.json'))
 allowed={'backend/'+n for n in baseline['backendFiles']}|{
 'ops/onaria-retention.service','ops/onaria-retention.timer',
 'ops/onaria-backend.service.d/retention-logs.conf','ops/journald@onaria.conf',
 'ops/onaria-nginx-log-format.conf','ops/onaria-nginx.conf','ops/onaria-logrotate',
 'ops/onaria-legacy-backup-retention.service','ops/onaria-legacy-backup-retention.timer','ops/retention-release-baseline.json'}
 if set(manifest['files'])!=allowed:raise RuntimeError('Release allowlist mismatch')
 for n,sha in baseline['backendFiles'].items():
  p=backend/n
  if p.is_symlink() or (digest(p) if p.exists() else None)!=sha:raise RuntimeError('Production baseline changed: '+n)
 nginx=Path('/etc/nginx/sites-available/onaria')
 if digest(nginx)!=baseline['nginxSha256']:raise RuntimeError('ONARIA nginx baseline changed')
 version=manifest['commit']
 if len(version)!=40 or any(c not in '0123456789abcdef' for c in version):raise RuntimeError('Invalid commit')
 work=Path('/opt/onaria-retention-releases')/version
 work.mkdir(parents=True,mode=0o700,exist_ok=False)
 stage=work/'artifact';stage.mkdir(mode=0o700)
 for n in names:
  p=stage/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(z.read(n));p.chmod(0o600)
ops={
 'ops/onaria-legacy-backup-retention.service':'/etc/systemd/system/onaria-legacy-backup-retention.service',
 'ops/onaria-legacy-backup-retention.timer':'/etc/systemd/system/onaria-legacy-backup-retention.timer',
 'ops/onaria-retention.service':'/etc/systemd/system/onaria-retention.service',
 'ops/onaria-retention.timer':'/etc/systemd/system/onaria-retention.timer',
 'ops/onaria-backend.service.d/retention-logs.conf':'/etc/systemd/system/onaria-backend.service.d/retention-logs.conf',
 'ops/journald@onaria.conf':'/etc/systemd/journald@onaria.conf',
 'ops/onaria-nginx-log-format.conf':'/etc/nginx/conf.d/onaria-retention-log-format.conf',
 'ops/onaria-nginx.conf':'/etc/nginx/sites-available/onaria',
 'ops/onaria-logrotate':'/etc/logrotate.d/onaria-retention',
}
targets={n:backend/n.removeprefix('backend/') for n in manifest['files'] if n.startswith('backend/')}
targets.update({n:Path(p) for n,p in ops.items()})
for n,p in targets.items():
 if p.is_symlink():raise RuntimeError('Refusing symlink target')
 if n.startswith('ops/') and n!='ops/onaria-nginx.conf' and p.exists():raise RuntimeError('Unexpected existing release setting: '+n)
previous=work/'previous';previous.mkdir(mode=0o700)
existed={}
for n,p in targets.items():
 existed[n]=p.exists()
 if p.exists():
  saved=previous/n;saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,saved)
def install(source,target):
 target.parent.mkdir(parents=True,exist_ok=True)
 temp=target.with_name(target.name+'.onaria-retention-new')
 shutil.copyfile(source,temp);temp.chmod(0o644)
 if str(target).startswith(str(backend)+'/'):
  owner=backend.stat();os.chown(temp,owner.st_uid,owner.st_gid)
 os.replace(temp,target)
restarted=False
try:
 for n,p in targets.items():install(stage/n,p)
 logs=Path('/var/log/nginx/onaria');logs.mkdir(mode=0o750,exist_ok=True)
 os.chown(logs,pwd.getpwnam('www-data').pw_uid,grp.getgrnam('adm').gr_gid)
 run(['nginx','-t'])
 run(['systemd-analyze','verify','/etc/systemd/system/onaria-retention.service','/etc/systemd/system/onaria-retention.timer'])
 run(['logrotate','-d','/etc/logrotate.d/onaria-retention'])
 run(['systemctl','daemon-reload'])
 run(['systemctl','restart','onaria-backend.service']);restarted=True
 run(['systemctl','is-active','--quiet','onaria-backend.service'])
 health=None
 for attempt in range(15):
  r=subprocess.run(['curl','--fail','--silent','--max-time','2','http://127.0.0.1:8787/health'],capture_output=True,text=True)
  if r.returncode==0:
   health=json.loads(r.stdout)
   if health.get('status')=='ok':break
  time.sleep(1)
 if not health or health.get('status')!='ok':raise RuntimeError('Backend health check failed')
 run(['systemctl','reload','nginx'])
 run(['systemctl','start','onaria-backup.service'])
 preview=json.loads(run(['node',str(backend/'scripts/retention_maintenance.js')]).stdout)
 print('RETENTION_PREVIEW',json.dumps(preview))
 run(['systemctl','start','onaria-retention.service'])
 run(['systemctl','enable','--now','onaria-retention.timer'])
 run(['systemctl','start','onaria-legacy-backup-retention.service'])
 run(['systemctl','enable','--now','onaria-legacy-backup-retention.timer'])
 print('RELEASE_APPLIED',json.dumps({'commit':version,'version':manifest['version'],'backendRestarted':True,'health':'ok'}))
 (work/'result.json').write_text(json.dumps({'commit':version,'version':manifest['version'],'status':'applied','retentionPreview':preview},indent=2)+'\n')
except Exception:
 for n,p in targets.items():
  if existed[n]:install(previous/n,p)
  elif p.exists():p.unlink()
 run(['systemctl','daemon-reload'])
 if restarted:run(['systemctl','restart','onaria-backend.service'])
 run(['nginx','-t']);run(['systemctl','reload','nginx'])
 raise
