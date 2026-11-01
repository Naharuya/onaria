from pathlib import Path
import subprocess
root=Path('/Users/ari/ARI/projects/onaria')
line=next((x for x in (root/'ios/Flutter/Kakao.local.xcconfig').read_text().splitlines() if x.startswith('ONARIA_KAKAO_NATIVE_APP_KEY=')), None)
if not line:
    raise SystemExit('protected Kakao key not configured')
key=line.split('=',1)[1].strip()
if not key:
    raise SystemExit('protected Kakao key empty')
base=['flutter','build']
common=['--release','--build-name=1.0.0','--build-number=20',f'--dart-define=ONARIA_KAKAO_NATIVE_APP_KEY={key}']
subprocess.run(base+['apk']+common,cwd=root,check=True)
subprocess.run(base+['appbundle']+common,cwd=root,check=True)
print('BUILD20_RELEASE_OK')
