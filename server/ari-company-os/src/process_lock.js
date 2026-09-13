import fs from 'node:fs';
export function acquireLock(file) {
  for (let attempt=0; attempt<2; attempt++) {
    try {
      const fd=fs.openSync(file,'wx',0o600); fs.writeFileSync(fd,String(process.pid)); fs.closeSync(fd);
      return () => { if (fs.existsSync(file) && fs.readFileSync(file,'utf8') === String(process.pid)) fs.unlinkSync(file); };
    } catch (e) {
      if (e.code !== 'EEXIST') throw e;
      const pid=Number(fs.readFileSync(file,'utf8'));
      if (!Number.isInteger(pid) || pid <= 0) throw new Error('invalid_lock_requires_review');
      try { process.kill(pid,0); throw new Error('daemon_already_running'); }
      catch (error) { if (error.code !== 'ESRCH') throw error; fs.unlinkSync(file); }
    }
  }
  throw new Error('lock_unavailable');
}
