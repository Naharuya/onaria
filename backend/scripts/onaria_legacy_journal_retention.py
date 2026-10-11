"""Remove only aged ONARIA entries; preserve other journal fields exactly.
Default stages and verifies candidates only. --apply atomically replaces archives.
Source: https://systemd.io/JOURNAL_EXPORT_FORMATS/
"""
from pathlib import Path
import collections, datetime, fcntl, hashlib, os, re, shutil, struct, subprocess, sys
UNIT = b'onaria-backend.service'
ADDRESS_FIELDS = {b'__CURSOR', b'__SEQNUM', b'__SEQNUM_ID'}

def entries(data):
    offset = 0
    while offset < len(data):
        start = offset; fields = []
        while True:
            end = data.find(b'\n', offset)
            if end < 0: raise ValueError('Truncated journal export')
            line = data[offset:end]; offset = end + 1
            if not line: break
            if b'=' in line:
                key, value = line.split(b'=', 1)
            else:
                key = line
                if offset + 8 > len(data): raise ValueError('Truncated binary length')
                size = struct.unpack_from('<Q', data, offset)[0]; offset += 8
                if offset + size >= len(data): raise ValueError('Truncated binary field')
                value = data[offset:offset + size]; offset += size
                if data[offset:offset+1] != b'\n': raise ValueError('Invalid binary separator')
                offset += 1
            if not re.fullmatch(rb'[A-Z_][A-Z_0-9]*', key): raise ValueError('Invalid journal field')
            fields.append((key, value))
        if not fields: raise ValueError('Empty journal entry')
        yield fields, data[start:offset]

def fingerprint(fields):
    h = hashlib.sha256()
    for key, value in sorted((k,v) for k,v in fields if k not in ADDRESS_FIELDS):
        h.update(struct.pack('<QQ',len(key),len(value))); h.update(key); h.update(value)
    return h.hexdigest()

def filter_export(data, cutoff):
    kept = []; expected = collections.Counter(); removed = 0; total = 0
    for fields, raw in entries(data):
        total += 1
        values = collections.defaultdict(list)
        for key, value in fields: values[key].append(value)
        times = values[b'__REALTIME_TIMESTAMP']
        if len(times) != 1 or not times[0].isdigit(): raise ValueError('Missing unique timestamp')
        units = values[b'_SYSTEMD_UNIT']
        # Ambiguous/multiple units are retained, never guessed.
        if units == [UNIT] and 0 < int(times[0]) < cutoff:
            removed += 1
        else:
            kept.append(raw); expected[fingerprint(fields)] += 1
    return b''.join(kept), expected, removed, total

def command(args, **kwargs):
    result = subprocess.run(args, capture_output=True, **kwargs)
    if result.returncode: raise RuntimeError('Journal tool failed; raw output suppressed')
    return result.stdout

def maintain(root, work, tool, apply=False):
    if os.geteuid() != 0: raise RuntimeError('Root required for journal maintenance')
    cutoff = int((datetime.datetime.now(datetime.timezone.utc)-datetime.timedelta(days=14)).timestamp()*1e6)
    work.mkdir(parents=True, mode=0o700, exist_ok=True)
    with (work/'.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        plans=[]; candidates=[]
        try:
            for source in sorted(root.glob('*/user-1000@*.journal')):
                if '.onaria' in str(source.parent): continue
                if source.is_symlink() or source.parent.is_symlink(): raise RuntimeError('Symlink journal refused')
                before=hashlib.sha256(source.read_bytes()).hexdigest(); info=source.stat()
                raw=command(['journalctl','--file='+str(source),'--no-pager','-o','export'])
                kept, expected, removed, total=filter_export(raw,cutoff)
                if not removed: continue
                if hashlib.sha256(source.read_bytes()).hexdigest()!=before: raise RuntimeError('Source journal changed while reading')
                stage=source.parent/'.onaria-retention-staging'
                if stage.is_symlink(): raise RuntimeError('Symlink staging directory refused')
                stage.mkdir(mode=0o700,exist_ok=True)
                if stage.stat().st_uid!=0 or stage.stat().st_mode & 0o077: raise RuntimeError('Private root staging required')
                candidate=stage/(before+'.journal')
                if candidate.exists(): raise RuntimeError('Unexpected existing candidate')
                candidates.append(candidate)
                if kept:
                    command([str(tool),'--split-mode=none','--output='+str(candidate),'-'],input=kept)
                    command(['journalctl','--file='+str(candidate),'--verify'])
                    actual=collections.Counter(fingerprint(fields) for fields,_ in entries(command(['journalctl','--file='+str(candidate),'--no-pager','-o','export'])))
                    if actual != expected: raise RuntimeError('Retained journal records changed')
                    os.chown(candidate,info.st_uid,info.st_gid);shutil.copystat(source,candidate)
                    with candidate.open('rb') as handle: os.fsync(handle.fileno())
                plans.append((source,candidate,before,removed,total,len(expected)))
            for source,_,before,_,_,_ in plans:
                if source.is_symlink() or hashlib.sha256(source.read_bytes()).hexdigest()!=before: raise RuntimeError('Source journal changed during verification')
            if apply:
                for source,candidate,_,_,_,_ in plans:
                    if candidate.exists(): os.replace(candidate,source)
                    else: source.unlink()
                    fd=os.open(source.parent,os.O_RDONLY|os.O_DIRECTORY)
                    try: os.fsync(fd)
                    finally: os.close(fd)
            return {'mode':'apply' if apply else 'verified-dry-run','files':len(plans),'removedOnariaEntries':sum(p[3] for p in plans),'retainedEntries':sum(p[4]-p[3] for p in plans),'retainedFieldsAndTimestampsVerified':True,'otherEntriesRemoved':0}
        finally:
            for candidate in candidates:
                if candidate.exists(): candidate.unlink()
                try: candidate.parent.rmdir()
                except OSError: pass

if __name__=='__main__':
    import argparse,json
    parser=argparse.ArgumentParser();parser.add_argument('--apply',action='store_true');parser.add_argument('--tool',required=True);args=parser.parse_args()
    result=maintain(Path('/var/log/journal'),Path('/opt/onaria-retention-releases/legacy-journal-maintenance'),Path(args.tool),args.apply)
    print(json.dumps(result))
