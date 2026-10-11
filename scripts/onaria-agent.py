#!/usr/bin/env python3
"""Launch a saved ONARIA role with the existing Codex login and model settings."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tomllib

ROOT = Path(__file__).resolve().parents[1]


def profiles():
    return {
        data['name']: data
        for path in sorted((ROOT / '.codex/agents').glob('*.toml'))
        for data in [tomllib.loads(path.read_text())]
    }


def main():
    roles = profiles()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('role', nargs='?', choices=sorted(roles))
    parser.add_argument('task', nargs='?', help='Task to give the selected role')
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.list or args.check:
        for name, role in roles.items():
            for key in ('name', 'description', 'developer_instructions', 'sandbox_mode'):
                if not isinstance(role.get(key), str) or not role[key].strip():
                    parser.error(f'Invalid profile {name}: {key}')
            print(f'{name}: {role["description"]}')
        schedule = json.loads((ROOT / '.codex/onaria-schedule.json').read_text())
        print(f'Roles: {len(roles)}; recurring schedule enabled: {schedule["enabled"]}')
        return
    if not args.role or not args.task:
        parser.error('Supply a role and task, or use --list / --check')
    codex = shutil.which('codex')
    if not codex:
        parser.error('Codex CLI is not on PATH')
    if 'name: onaria' not in (ROOT / 'pubspec.yaml').read_text():
        parser.error('Expected ONARIA project root')
    role = roles[args.role]
    command = [codex, '-C', str(ROOT), '-s', role['sandbox_mode'], '-a', 'on-request',
               '-c', 'developer_instructions=' + json.dumps(role['developer_instructions'], ensure_ascii=False),
               args.task]
    raise SystemExit(subprocess.call(command, cwd=ROOT))


if __name__ == '__main__':
    main()
