#!/usr/bin/env python3
"""Render user/system launchd configuration; replace only this managed service with a backup."""
from pathlib import Path
import argparse,datetime,plistlib,shutil
parser=argparse.ArgumentParser();parser.add_argument('--replace-managed',action='store_true');args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
state=Path('/Users/server/ari-server/runtime/ari-company-os');logs=Path('/Users/server/ari-server/logs/ari-company-os')
target=Path('/Users/server/Library/LaunchAgents/com.ari.company-os.plist')
node=shutil.which('node')
if not node:raise SystemExit('Node missing')
config={'Label':'com.ari.company-os','ProgramArguments':[node,str(root/'bin/ari-manager.js'),'daemon'],'WorkingDirectory':str(root),'RunAtLoad':True,'KeepAlive':True,'ThrottleInterval':10,'ExitTimeOut':30,'ProcessType':'Background','StandardOutPath':str(logs/'launchd.stdout.log'),'StandardErrorPath':str(logs/'launchd.stderr.log'),'EnvironmentVariables':{'PATH':'/opt/homebrew/bin:/Users/server/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin','HOME':'/Users/server','ARI_STATE_ROOT':str(state),'ARI_LOG_DIR':str(logs),'ARI_POLL_INTERVAL_MS':'900000','ARI_WATCH_POLL_INTERVAL_MS':'15000','ARI_QUIET_WINDOW_MS':'1200000','ARI_CODEX_REPAIR_ENABLED':'true','ARI_CODEX_CODING_ENABLED':'true','KSTOCK_LIVE_TRADING_ENABLED':'false','KSTOCK_AI_MODE':'mock'}}
for directory in (state,logs,target.parent):directory.mkdir(parents=True,exist_ok=True)
data=plistlib.dumps(config)
if target.exists() and target.read_bytes()!=data:
 old=plistlib.loads(target.read_bytes())
 if not args.replace_managed or old.get('Label')!='com.ari.company-os' or old.get('ProgramArguments',[None,None])[1]!=str(root/'bin/ari-manager.js'):raise SystemExit('Existing unmanaged or unapproved plist preserved')
 backup=state/'backups'/('launchd-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'.plist');backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target,backup)
 target.write_bytes(data)
elif not target.exists():
 with target.open('xb') as f:f.write(data)
(root/'launchd/com.ari.company-os.plist.template').write_bytes(data)
system=dict(config,UserName='server',GroupName='staff')
(root/'launchd/com.ari.company-os.system.plist').write_bytes(plistlib.dumps(system))
print(target)
