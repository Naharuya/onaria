import { Router } from 'express';
import { createHash, randomBytes, timingSafeEqual } from 'node:crypto';
import rateLimit from 'express-rate-limit';

const digest = value => createHash('sha256').update(String(value)).digest();
const equal = (a, b) => timingSafeEqual(digest(a), digest(b));

// Single-process sessions intentionally expire on restart. The ADMIN_TOKEN is
// only a login credential; it is never returned or stored in browser storage.
export function adminAuth({ token, production = false, allowBearer = !production, now = Date.now, ttlMs = 30 * 60_000, accounts = null, audit = null }) {
  const log = (req, res, entry) => { try { audit?.record({ requestId: res.locals.requestId, ...entry }); return true; } catch { return false; } };
  const router = Router();
  const sessions = new Map();
  const cookieName = production ? '__Host-onaria_admin' : 'onaria_admin_dev';
  const options = { httpOnly: true, secure: production, sameSite: 'strict', path: '/' };
  const prune = () => { for (const [key, session] of sessions) if (session.expires <= now()) sessions.delete(key); };
  const sessionKey = req => {
    const value = (req.get('cookie') || '').split(';').map(v => v.trim()).find(v => v.startsWith(cookieName + '='))?.slice(cookieName.length + 1);
    return value ? digest(value).toString('hex') : '';
  };
  const sameOrigin = req => req.get('origin') === `${req.protocol}://${req.get('host')}`;
  router.use((req, res, next) => {
    res.set({ 'Cache-Control': 'no-store', 'X-Robots-Tag': 'noindex, nofollow' });
    if (production && !req.secure) return res.status(426).json({ message: 'HTTPS 연결이 필요합니다.' });
    prune();
    next();
  });
  router.post('/session', rateLimit({ windowMs: 15 * 60_000, limit: 5, standardHeaders: 'draft-8', legacyHeaders: false }), async (req, res, next) => {
    try {
      if (!sameOrigin(req)) return res.status(403).json({ message: '동일한 사이트에서 로그인하세요.' });
      let principal = null;
      if (typeof req.body?.username === 'string' && accounts) {
        const account = await accounts.authenticate(req.body.username, req.body.password);
        if (account) principal = { actor: `account:${account.username}`, role: account.role, accountId: account.id };
      } else if (token && typeof req.body?.token === 'string' && equal(req.body.token, token)) {
        principal = { actor: 'owner-token', role: 'owner', accountId: null };
      }
      if (!principal) {
        log(req, res, { actor: typeof req.body?.username === 'string' ? `account:${req.body.username.slice(0, 40)}` : 'anonymous', action: 'admin.login', outcome: 'failure' });
        return res.status(401).json({ message: '관리자 인증 정보를 확인하세요.' });
      }
      if (sessions.size >= 100) return res.status(503).json({ message: '잠시 후 다시 시도하세요.' });
      // A session is only issued when the login itself could be recorded.
      if (!log(req, res, { actor: principal.actor, role: principal.role, action: 'admin.login', outcome: 'success' })) {
        return res.status(503).json({ message: '감사 기록을 사용할 수 없어 로그인할 수 없습니다.' });
      }
      sessions.delete(sessionKey(req));
      const id = randomBytes(32).toString('base64url');
      const csrfToken = randomBytes(32).toString('base64url');
      sessions.set(digest(id).toString('hex'), { csrfToken, expires: now() + ttlMs, ...principal });
      res.cookie(cookieName, id, { ...options, maxAge: ttlMs });
      return res.json({ authenticated: true, csrfToken, role: principal.role, expiresInSeconds: ttlMs / 1000 });
    } catch (error) { return next(error); }
  });
  router.use((req, res, next) => {
    // Retained for trusted server tooling in development; production opt-in only.
    if (allowBearer && token && equal(req.get('authorization') || '', `Bearer ${token}`)) { res.locals.admin = { actor: 'bearer-token', role: 'owner', accountId: null }; return next(); }
    const session = sessions.get(sessionKey(req));
    if (!session) return res.status(401).json({ message: '관리자 인증이 필요합니다.' });
    if (!['GET', 'HEAD', 'OPTIONS'].includes(req.method) && (!sameOrigin(req) || !equal(req.get('x-csrf-token') || '', session.csrfToken))) {
      return res.status(403).json({ message: '인증을 새로 확인한 뒤 다시 시도하세요.' });
    }
    let role = session.role;
    if (session.accountId) {
      const account = accounts?.get(session.accountId);
      if (!account || account.disabled) return res.status(401).json({ message: '관리자 인증이 필요합니다.' });
      role = account.role;
    }
    res.locals.adminSession = session;
    res.locals.admin = { actor: session.actor, role, accountId: session.accountId };
    next();
  });
  router.get('/session', (_req, res) => res.json({ authenticated: true, csrfToken: res.locals.adminSession?.csrfToken ?? null, role: res.locals.admin?.role ?? null }));
  router.delete('/session', (req, res) => {
    log(req, res, { actor: res.locals.admin?.actor ?? 'unknown', role: res.locals.admin?.role, action: 'admin.logout', outcome: 'success' });
    sessions.delete(sessionKey(req));
    res.clearCookie(cookieName, options);
    res.status(204).end();
  });
  return router;
}
