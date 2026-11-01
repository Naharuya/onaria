#!/usr/bin/env python3
"""Build a labelled app; never installs, deploys or changes application IDs."""
import argparse, json, os, re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = json.loads((ROOT / 'app-channel.json').read_text())

def display_name(channel):
    if channel not in ('dev', 'test', 'prod'):
        raise ValueError('channel must be dev, test or prod')
    return CONFIG['name'] + {'dev': ' DEV', 'test': ' TEST', 'prod': ''}[channel]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('channel', choices=['dev', 'test', 'prod'])
    parser.add_argument('target', choices=['apk', 'appbundle', 'ios', 'ipa', 'web'])
    parser.add_argument('--dry-run', action='store_true')
    args, extra = parser.parse_known_args()
    if extra[:1] == ['--']: extra = extra[1:]
    if any(x in ('run', 'install', 'clean') for x in extra):
        parser.error('Only build arguments are accepted; installation is a separate verified step.')
    env = os.environ.copy()
    env['ORG_GRADLE_PROJECT_ariAppChannel'] = args.channel
    if args.target in ('ios', 'ipa'):
        if not (ROOT / 'ios/Runner/Info.plist').exists():
            parser.error('This project has no iOS target.')
        if env.get('XCODE_XCCONFIG_FILE'):
            parser.error('Existing XCODE_XCCONFIG_FILE: combine settings explicitly before building.')
        env['XCODE_XCCONFIG_FILE'] = str(ROOT / 'ios/Flutter/Channels' / (args.channel + '.xcconfig'))
    # A display channel is not a server environment or a store track detector.
    print(json.dumps({'channel': args.channel, 'displayName': display_name(args.channel),
                      'target': args.target, 'applicationIdChanged': False,
                      'serverChanged': False, 'dryRun': args.dry_run}, ensure_ascii=False), flush=True)
    if args.dry_run: return 0
    result = subprocess.run(['flutter', 'build', args.target,
                             '--dart-define=ARI_APP_CHANNEL=' + args.channel, *extra], cwd=ROOT, env=env)
    if result.returncode: return result.returncode
    if args.target == 'web':
        out = ROOT / 'build/web'
        manifest = out / 'manifest.json'
        if not manifest.exists(): raise RuntimeError('Built PWA manifest is missing.')
        data = json.loads(manifest.read_text())
        data['name'] = data['short_name'] = display_name(args.channel)
        manifest.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
        index = out / 'index.html'
        text = index.read_text()
        text = re.sub(r'<title>.*?</title>', '<title>' + display_name(args.channel) + '</title>', text, flags=re.S)
        text = re.sub(r'(<meta\s+name="apple-mobile-web-app-title"\s+content=")[^"]*(")',
                      lambda m: m[1] + display_name(args.channel) + m[2], text)
        index.write_text(text)
        # Flutter's generated service-worker hashes refer to the pre-labelled files.
        # Refuse deployment of a stale precache; web labels require a fresh web cache strategy.
        worker = out / 'flutter_service_worker.js'
        if worker.exists():
            import hashlib
            text = worker.read_text()
            for rel in ['index.html', 'manifest.json']:
                digest = hashlib.md5((out / rel).read_bytes()).hexdigest()
                text = re.sub(r'("' + re.escape(rel) + r'"\s*:\s*")[^"]*(")',
                              lambda m: m[1] + digest + m[2], text)
                if rel == 'index.html':
                    text = re.sub(r'("/"\s*:\s*")[^"]*(")',lambda m:m[1]+digest+m[2],text)
            worker.write_text(text)
    return 0

if __name__ == '__main__':
    sys.exit(main())
