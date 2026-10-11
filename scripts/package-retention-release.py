from pathlib import Path
import hashlib,json,subprocess,zipfile,re
root=Path(__file__).resolve().parent.parent
baseline=json.loads((root/'ops/retention-release-baseline.json').read_text())
paths=['backend/'+p for p in baseline['backendFiles']]
paths += ['ops/onaria-retention.service','ops/onaria-retention.timer',
 'ops/onaria-backend.service.d/retention-logs.conf','ops/journald@onaria.conf',
 'ops/onaria-nginx-log-format.conf','ops/onaria-nginx.conf','ops/onaria-logrotate',
 'ops/retention-release-baseline.json']
out=root/'build/retention-release';out.mkdir(parents=True,exist_ok=True)
manifest={'version':'1.0.0-retention.1','commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),'files':{}}
for name in paths:
 p=root/name
 if p.is_symlink() or not p.is_file():raise ValueError('Missing/unsafe release file: '+name)
 data=p.read_bytes()
 if re.search(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY|sk-(?:proj-)?[A-Za-z0-9_-]{60,}|GOCSPX-[A-Za-z0-9_-]{20,}',data):raise ValueError('Credential pattern: '+name)
 if name.endswith('.js'):subprocess.run(['node','--check',str(p)],check=True)
 manifest['files'][name]=hashlib.sha256(data).hexdigest()
manifestBytes=(json.dumps(manifest,indent=2)+'\n').encode()
archive=out/'onaria-retention-release.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for name in paths:z.write(root/name,name)
 z.writestr('release-manifest.json',manifestBytes)
digest=hashlib.sha256(archive.read_bytes()).hexdigest()
(out/'onaria-retention-release.zip.sha256').write_text(digest+'\n')
(out/'release-manifest.json').write_bytes(manifestBytes)
print(json.dumps({'commit':manifest['commit'],'files':len(paths),'sha256':digest}))
