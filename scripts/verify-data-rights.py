#!/usr/bin/env python3
"""Read-only source/release evidence check; never deploys or deletes data."""
from pathlib import Path
import argparse,json,sys,hashlib
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--source-only',action='store_true');args=parser.parse_args()
errors=[]
def need(condition,label):
 if not condition:errors.append(label)
notice=(root/'lib/data_rights.dart').read_text()
need('class DataRightsNotice' in notice and '회원탈퇴' in notice,'common disclosure missing')
need((root/'docs/DATA_RIGHTS_STANDARD.md').is_file(),'common standard missing')
profile=json.loads((root/'backend/src/privacy/data_rights_profile.json').read_text())
need(profile['origin'].startswith('https://') and '.invalid' not in profile['origin'],'invalid public origin')
need('@' in profile['supportEmail'],'deletion contact missing')
if profile['app']=='MAEON':
 html=(root/'web/account-deletion.html').read_text()
 need((root/'web/data-controls.html').is_file(),'public data controls missing')
else:
 html=(root/'backend/public/data-rights.html').read_text()
 need((root/'lib/app/record_preferences.dart').is_file(),'scoped record deletion missing')
 ui=(root/'lib/features/privacy_page.dart').read_text()
 need('.invalid/' not in ui,'invalid policy link')
for text in [profile['app'],'mailto:','앱 재설치 없이','본인 확인','회원탈퇴','서버 기록','처리 실패']:
 need(text in html,'deletion page missing: '+text)
manifest=(root/'android/app/src/main/AndroidManifest.xml').read_text()
need('android:allowBackup="false"' in manifest,'Android backup policy mismatch')
evidencePath=root/'docs/data-rights-verification-20261101.json'
evidence=json.loads(evidencePath.read_text()) if evidencePath.exists() else {}
release=[]
if not args.source_only:
 for rel,digest in evidence.get('sourceSha256',{}).items():
  source=root/rel
  if not source.is_file() or hashlib.sha256(source.read_bytes()).hexdigest()!=digest:release.append('source changed after verification: '+rel)
 for field in ['productionDeployed','deviceValidationPassed','storeFormsVerified']:
  if evidence.get(field) is not True:release.append(field+' not verified')
 if not all(row.get('http')==200 and row.get('commonCandidateVisible') is True for row in evidence.get('publicUrls',[]) if 'account-deletion' in row['url']):release.append('public deletion candidate not verified')
 if not evidence.get('publicUrls'):release.append('public deletion URL not verified')
print(json.dumps({'project':profile['app'],'source':'PASS' if not errors else 'FAIL','errors':errors,'release':'NOT_ASSESSED' if args.source_only else 'BLOCKED' if release or errors else 'EVIDENCE_READY','remaining':release},ensure_ascii=False,indent=2))
sys.exit(1 if errors else 0 if args.source_only or not release else 2)
