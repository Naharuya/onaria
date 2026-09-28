import express from 'express';
import helmet from 'helmet';
import { randomBytes } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { createBuddhistPack } from './buddhist/pack.js';
import { createReligionRouter } from './router.js';

const publicDirectory = fileURLToPath(new URL('./public/', import.meta.url));
export function createBuddhistDevApp() {
  if (process.env.NODE_ENV === 'production') throw Error('TEST_DATA_ONLY_REQUIRED');
  const pack = createBuddhistPack();
  const core = createReligionRouter(pack);
  const sessions = new Map(); // Per-process, isolated, expiring. No DB or user data access.
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet({ strictTransportSecurity: false, contentSecurityPolicy: { directives: {
    defaultSrc: ["'self'"], scriptSrc: ["'self'"], styleSrc: ["'self'"],
    connectSrc: ["'self'"], objectSrc: ["'none'"], frameAncestors: ["'none'"], upgradeInsecureRequests: null,
  } } }));
  app.use((req, res, next) => {
    res.set('Cache-Control', 'no-store');
    const expectedHost = `127.0.0.1:${req.socket.localPort}`;
    if (req.headers.host !== expectedHost || !['127.0.0.1', '::ffff:127.0.0.1'].includes(req.socket.remoteAddress)) return res.sendStatus(403);
    if (req.headers['sec-fetch-site'] === 'cross-site') return res.sendStatus(403);
    if (req.headers.origin && req.headers.origin !== `http://${expectedHost}`) return res.sendStatus(403);
    if (req.method === 'POST' && req.headers.origin !== `http://${expectedHost}`) return res.sendStatus(403);
    next();
  });
  app.use(express.json({ limit: '8kb' }));
  app.get('/', (req, res) => {
    const now = Date.now();
    for (const [key, session] of sessions) if (session.expires < now) sessions.delete(key);
    if (sessions.size >= 100) return res.sendStatus(429);
    const token = randomBytes(32).toString('hex');
    sessions.set(token, { riskLevel: 0, expires: now + 3600_000, counts: { respond: 0, search: 0, cards: 0 } });
    res.cookie('buddhist_dev_session', token, { httpOnly: true, sameSite: 'strict', path: '/', maxAge: 3600_000 });
    res.sendFile(`${publicDirectory}/index.html`);
  });
  app.use('/api', (req, res, next) => {
    const token = /(?:^|;\s*)buddhist_dev_session=([a-f0-9]{64})(?:;|$)/.exec(req.headers.cookie ?? '')?.[1];
    const session = sessions.get(token);
    if (!session || session.expires < Date.now()) return res.sendStatus(401);
    req.devSession = session;
    next();
  });
  app.post('/api/respond', async (req, res) => {
    req.devSession.counts.respond++;
    const { userMessage, religion = 'buddhist' } = req.body ?? {};
    if (typeof userMessage !== 'string' || !userMessage.trim() || userMessage.length > 2000
      || Object.keys(req.body).some((key) => !['userMessage', 'religion'].includes(key))) return res.sendStatus(400);
    try {
      const result = await core.respond({ userMessage, religion, session: { riskLevel: req.devSession.riskLevel } });
      req.devSession.riskLevel = Math.max(req.devSession.riskLevel, result.riskLevel ?? 0);
      res.json(result);
    } catch (error) {
      if (error.message === 'PACK_MISMATCH') return res.status(400).json({ error: 'PACK_MISMATCH' });
      throw error;
    }
  });
  app.get('/api/search', (req, res) => {
    req.devSession.counts.search++;
    if (req.devSession.riskLevel > 0) return res.status(409).json({ error: 'SAFETY_FIRST' });
    if (typeof req.query.q !== 'string' || req.query.q.length > 2000) return res.sendStatus(400);
    res.json({ mode: 'TEST_DATA_ONLY', results: pack.provider.search(req.query.q) });
  });
  app.post('/api/cards', (req, res) => {
    req.devSession.counts.cards++;
    if (req.devSession.riskLevel > 0) return res.status(409).json({ error: 'SAFETY_FIRST' });
    if (!req.body || Object.keys(req.body).join(',') !== 'scriptureId') return res.sendStatus(400);
    try { res.json(pack.provider.mindCard(req.body.scriptureId)); }
    catch { res.status(404).json({ error: 'UNSUPPORTED_SCRIPTURE' }); }
  });
  // Local browser session capability only; never production admin authentication.
  app.use('/api/admin', (req, res, next) => {
    if (req.method !== 'GET') return res.sendStatus(404);
    if (Object.keys(req.query).some(key => key !== 'religion') ||
        (req.query.religion !== undefined && req.query.religion !== 'buddhist')) {
      return res.status(400).json({ error: 'PACK_MISMATCH' });
    }
    next();
  });
  app.get('/api/admin', (req, res) => res.json({ ...pack.provider.status(),
    storage: 'isolated-ephemeral-memory', modelCalls: 0, openAiClientCreations: 0,
    publicationEnabled: false, adminMode: 'read-only-local-development' }));
  app.get('/api/admin/diagnostics', (req, res) => res.json({
    mode: 'TEST_DATA_ONLY', religion: 'buddhist',
    scope: 'current-browser-session-only', counts: { ...req.devSession.counts },
    privacy: { storesMessages: false, storesIdentity: false, exposesSecrets: false },
    controls: { import: false, approveExternal: false, publish: false, resetData: false },
    copyrightStatus: 'BLOCKED_EXTERNAL_REVIEW',
    dataPolicy: 'provider-canonical-fixtures-only',
  }));
  app.use(express.static(publicDirectory, { index: false, etag: false, maxAge: 0 }));
  app.use((_req, res) => res.sendStatus(404));
  app.use((_error, _req, res, _next) => res.status(400).json({ error: 'INVALID_REQUEST' }));
  return app;
}
