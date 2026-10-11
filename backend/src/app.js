import cors from 'cors';
import { AccountMergeError, mergeHash } from './account_merge_store.js';
import express from 'express';
import { fileURLToPath } from 'node:url';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import { ZodError } from 'zod';
import { assessRequestCrisis, crisisResponse } from './crisis.js';
import { logSafetyAssessment } from './safety_event.js';
import { requestSchema, responseSchema } from './schema.js';
import { memberSchema, publicMember } from './member_schema.js';
import { createMemberStore } from './member_store.js';
import { routeAgent } from './ai_router.js';
import { IdentityError } from './auth/identity_verifier.js';
import { appLinksRouter } from './app_links.js';
import { adminAuth } from './admin_auth.js';
import { websiteRouter } from './website.js';
import { createWebMetrics, modelUsageSample } from './web_metrics.js';
import { createFeedbackMetrics, feedbackSchema } from './feedback.js';

export function createApp({ generate, adminSettings, allowedOrigins = [], appToken = '', adminToken = '', logger = console, memberStore = createMemberStore(), identity = { required: false, verify: null }, providerIdentity = null, appleRevocation = null, appleAndroidAuth = null, memberSessions = null, deletionManifest = null, accountMergeEnabled = false, production = false, trustProxy = false, publicOrigin = 'https://onaria.ai.kr', allowAdminBearer = !production, webMetrics = createWebMetrics() }) {
  const app = express();
  const startedAt = new Date();
  const metrics = { requests: 0, chats: 0, crises: 0, errors: 0, statusCodes: {} };
  const feedback = createFeedbackMetrics();
  const memberVisible = member => member && !(memberStore.recordOwnerIds?.(member.id) ?? [member.id]).some(id => deletionManifest?.contains?.(id));
  async function requireAccountProof(req, member) {
    const provider = req.body?.reauthProvider;
    const credential = req.body?.reauthCredential;
    if (!provider || !credential) throw new IdentityError(428);
    if (!providerIdentity) throw new IdentityError(503);
    const proof = await providerIdentity({ provider, credential });
    const owner = memberStore.findByProviderIdentity?.(proof.provider, proof.providerUserId);
    if (!memberVisible(owner) || owner.id !== member.id) throw new IdentityError();
    const current = memberSessions.verify(req.get('x-onaria-member-session'));
    const currentOwner = memberStore.findByProviderIdentity?.(current.provider, current.providerUserId);
    if (!memberVisible(currentOwner) || currentOwner.id !== member.id) throw new IdentityError();
    return proof;
  }
  app.disable('x-powered-by');
  app.set('trust proxy', trustProxy);
  app.use(helmet());
  app.use(appLinksRouter());
  app.use(cors({ origin(origin, cb) { cb(null, !origin || allowedOrigins.includes(origin)); } }));
  app.use('/v1', (_req, res, next) => {
    res.set('Cache-Control', 'no-store');
    next();
  });
  app.use(express.json({ limit: '16kb' }));
  app.use('/v1', rateLimit({ windowMs: 60_000, limit: 20, skip: req => /^\/admin(?:\/|$)/.test(req.path), standardHeaders: 'draft-8', legacyHeaders: false }));
  if (appleAndroidAuth) app.use('/v1/auth/apple/android', appleAndroidAuth.router());
  app.use('/v1/admin', rateLimit({ windowMs: 60_000, limit: 240, standardHeaders: 'draft-8', legacyHeaders: false }));
  app.use((req, res, next) => {
    metrics.requests += 1;
    res.on('finish', () => {
      const key = String(res.statusCode);
      metrics.statusCodes[key] = (metrics.statusCodes[key] || 0) + 1;
      if (res.statusCode >= 500) metrics.errors += 1;
    });
    next();
  });

  app.get('/health', (_req, res) => res.json({ status: 'ok', version: process.env.ONARIA_VERSION || '1.0.0', build: process.env.ONARIA_BUILD || '20' }));
  app.use('/v1/admin', adminAuth({ token: adminToken, production, allowBearer: allowAdminBearer }));
  app.use('/v1/admin/settings', (req, res, next) => {
    if (!adminSettings) return res.status(503).json({ message: '설정 저장소를 사용할 수 없습니다.' });
    next();
  });
  app.post('/v1/feedback', (req, res, next) => {
    if (appToken && req.get('authorization') !== `Bearer ${appToken}`) {
      return res.status(401).json({ message: '인증이 필요합니다.' });
    }
    try {
      feedback.add(feedbackSchema.parse(req.body));
      return res.status(202).json({ accepted: true });
    } catch (error) { return next(error); }
  });

  app.get('/v1/admin/feedback', (_req, res) => res.json(feedback.overview()));

  app.get('/v1/admin/settings', (_req, res) => {
    try { return res.json(adminSettings.status()); }
    catch { return res.status(503).json({ message: '설정을 불러오지 못했습니다.' }); }
  });
  app.put('/v1/admin/settings', (req, res) => {
    const apiKey = req.body?.apiKey;
    if (typeof apiKey !== 'string' || !/^sk-[A-Za-z0-9_-]{10,500}$/.test(apiKey)) return res.status(400).json({ message: 'OpenAI API 키 형식을 확인해 주세요.' });
    try { return res.json(adminSettings.update(apiKey)); }
    catch { return res.status(503).json({ message: '저장하지 못했습니다. 기존 설정을 유지합니다.' }); }
  });
  app.delete('/v1/admin/settings', (_req, res) => {
    try { return res.json(adminSettings.update('')); }
    catch { return res.status(503).json({ message: '삭제하지 못했습니다. 다시 시도해 주세요.' }); }
  });
  app.use('/admin', (req, res, next) => {
    res.set('X-Robots-Tag', 'noindex, nofollow');
    if (production && !req.secure) return res.status(426).type('text').send('HTTPS required');
    next();
  });
  app.get(['/admin', '/admin/', ...['dashboard', 'users', 'ai-usage', 'safety', 'content', 'analytics', 'system', 'privacy'].map(p => `/admin/${p}`)], (_req, res) => {
    res.set('Cache-Control', 'no-cache');
    res.sendFile(fileURLToPath(new URL('../public/admin.html', import.meta.url)));
  });
  app.use('/admin', express.static(fileURLToPath(new URL('../public', import.meta.url)), { index: false, maxAge: 0, dotfiles: 'deny' }));
  app.use(websiteRouter({ publicOrigin }));
  app.get('/v1/admin/overview', (req, res) => {
    res.set('Cache-Control', 'no-store');
    const members = memberStore.getAdminOverview?.() ?? { total: null, recent: [] };
    let aiUsage = { available: false };
    let modelUsage = { available: false, rows: [] };
    try { aiUsage = generate.usageLedger?.overview() ?? aiUsage; } catch { /* Existing overview stays available. */ }
    try { modelUsage = modelUsageSample(generate.usageLedger); } catch { /* Totals remain available. */ }
    return res.json({
      generatedAt: new Date().toISOString(),
      service: {
        status: 'operational',
        mode: generate.mode || 'local conversation',
        startedAt: startedAt.toISOString(),
        uptimeSeconds: Math.floor(process.uptime()),
      },
      metrics: { ...metrics,
      feedback: feedback.overview(), activeSessions: null },
      members,
      aiUsage,
      modelUsage,
      operations: webMetrics.overview(),
      aiRuntime: adminSettings?.runtimeStatus?.() ?? null,
    });
  });
  app.post('/v1/auth/signup', (req, res, next) => {
    try {
      const member = memberStore.create(memberSchema.parse(req.body));
      return res.status(201).json({ member: publicMember(member) });
    } catch (error) {
      if (error.code === 'PHONE_EXISTS') return res.status(409).json({ message: error.message });
      return next(error);
    }
  });
  app.post('/v1/auth/provider/signup', async (req, res, next) => {
    try {
      if (!providerIdentity || !memberSessions) throw new IdentityError(503);
      const trusted = await providerIdentity({ provider: req.body?.provider, credential: req.body?.credential });
      const existingIdentity = memberStore.findByProviderIdentity?.(trusted.provider, trusted.providerUserId);
      if (memberVisible(existingIdentity)) {
        return res.status(409).json({
          code: 'IDENTITY_ALREADY_REGISTERED',
          message: '이미 가입된 소셜 계정입니다. 로그인으로 다시 시도해 주세요.',
        });
      }

      const member = memberStore.create(memberSchema.parse({
        name: req.body?.name,
        phone: req.body?.phone,
        churchName: req.body?.churchName,
        termsAccepted: req.body?.termsAccepted,
        privacyAccepted: req.body?.privacyAccepted,
        adultConfirmed: req.body?.adultConfirmed,
        termsVersion: req.body?.termsVersion,
        privacyVersion: req.body?.privacyVersion,
        loginProvider: trusted.provider,
        providerUserId: trusted.providerUserId,
      }));
      const session = memberSessions.issue(trusted);
      return res.status(201).json({
        member: publicMember(member),
        sessionToken: session.token,
        expiresInSeconds: session.expiresInSeconds,
        linked: false,
      });
    } catch (error) {
      if (error.code === 'PHONE_EXISTS' || error.code === 'IDENTITY_EXISTS') {
        return res.status(409).json({ code: error.code, message: error.message });
      }
      return next(error);
    }
  });
  app.post('/v1/auth/provider/session', async (req, res, next) => {
    try {
      if (!providerIdentity || !memberSessions) throw new IdentityError(503);
      const trusted = await providerIdentity({ provider: req.body?.provider, credential: req.body?.credential });
      const member = memberStore.findByProviderIdentity?.(trusted.provider, trusted.providerUserId);
      if (!memberVisible(member)) return res.status(404).json({ code: 'PROVIDER_IDENTITY_NOT_FOUND', message: '가입된 회원 정보를 찾을 수 없습니다.' });
      const session = memberSessions.issue(trusted);
      return res.status(201).json({ sessionToken: session.token, expiresInSeconds: session.expiresInSeconds });
    } catch (error) { return next(error); }
  });
  app.post('/v1/account/providers', async (req, res, next) => {
    try {
      const sessionToken = req.get('x-onaria-member-session');
      if (!sessionToken || !providerIdentity || !memberSessions) throw new IdentityError();
      const currentIdentity = memberSessions.verify(sessionToken);
      const currentMember = memberStore.findByProviderIdentity?.(
        currentIdentity.provider,
        currentIdentity.providerUserId,
      );
      if (!memberVisible(currentMember)) throw new IdentityError();
      await requireAccountProof(req, currentMember);

      const trusted = await providerIdentity({
        provider: req.body?.provider,
        credential: req.body?.credential,
      });
      const owner = memberStore.findByProviderIdentity?.(
        trusted.provider,
        trusted.providerUserId,
      );
      if (memberVisible(owner) && owner.id !== currentMember.id) {
        return res.status(409).json({
          code: 'IDENTITY_EXISTS',
          message: '이미 다른 ONARIA 회원 계정에 연결된 소셜 계정입니다.',
        });
      }
      memberSessions.verify(sessionToken);
      const member = owner ?? memberStore.attachIdentity?.(
        currentMember.id,
        trusted.provider,
        trusted.providerUserId,
      );
      if (!memberVisible(member)) throw new IdentityError();
      const session = memberSessions.issue(trusted);
      memberSessions.revoke(sessionToken);
      return res.status(200).json({
        member: publicMember(member),
        sessionToken: session.token,
        expiresInSeconds: session.expiresInSeconds,
        linked: !owner,
      });
    } catch (error) {
      if (error.code === 'IDENTITY_EXISTS' || error.code === 'PROVIDER_ALREADY_LINKED') {
        return res.status(409).json({ code: error.code, message: error.message });
      }
      return next(error);
    }
  });

  const mergeAvailable = () => accountMergeEnabled && Boolean(
    deletionManifest?.recordMany && memberStore.prepareMerge && memberStore.confirmMerge &&
    memberSessions?.revokeIdentity && providerIdentity);
  function mergeAccount(req) {
    if (!mergeAvailable()) throw new AccountMergeError('MERGE_UNAVAILABLE',503);
    const token=req.get('x-onaria-member-session');
    if (!token) throw new IdentityError();
    const identity=memberSessions.verify(token);
    const member=memberStore.findByProviderIdentity(identity.provider,identity.providerUserId);
    if (!memberVisible(member)) throw new IdentityError();
    return {token,identity,member};
  }
  app.post('/v1/account/merge/prepare',async(req,res,next)=>{
    try {
      const current=mergeAccount(req);
      const targetProof=await requireAccountProof(req,current.member);
      const proof=await providerIdentity({provider:req.body?.sourceProvider,credential:req.body?.sourceCredential});
      const source=memberStore.findByProviderIdentity(proof.provider,proof.providerUserId);
      if (!memberVisible(source)) throw new AccountMergeError('MERGE_SOURCE_NOT_REGISTERED',404);
      if (source.id===current.member.id) throw new AccountMergeError('MERGE_ALREADY_SAME_ACCOUNT');
      const latest=mergeAccount(req);
      if (latest.member.id!==current.member.id) throw new IdentityError();
      const prepared=memberStore.prepareMerge(current.member.id,source.id,mergeHash(current.token),{targetProof,sourceProof:proof},()=>memberSessions.verify(current.token));
      return res.status(201).json(prepared);
    } catch(error) { return next(error); }
  });
  app.post('/v1/account/merge/confirm',(req,res,next)=>{
    try {
      const current=mergeAccount(req);
      if (req.body?.consent!==true) throw new AccountMergeError('MERGE_CONSENT_REQUIRED',400);
      const receipt=memberStore.confirmMerge(req.body?.attemptToken,current.member.id,mergeHash(current.token),identities=>{
        memberSessions.verify(current.token);
        for (const identity of identities) memberSessions.revokeIdentity(identity);
      });
      // If session issuance fails after commit, reauthenticate normally. GET
      // account exposes the authoritative owners, so retry never duplicates a merge.
      const session=memberSessions.issue(current.identity);
      return res.json({...receipt,sessionToken:session.token,expiresInSeconds:session.expiresInSeconds});
    } catch(error) {
      if (error instanceof IdentityError || error instanceof AccountMergeError) return next(error);
      return res.status(503).json({code:'MERGE_STATUS_RECHECK_REQUIRED',message:'통합 결과를 확인하지 못했어요. 다시 로그인한 뒤 계정 관리에서 확인해 주세요. 기록은 삭제하지 않았어요.'});
    }
  });

  app.get('/v1/account', (req, res, next) => {
    try {
      const sessionToken = req.get('x-onaria-member-session');
      if (!sessionToken || !memberSessions) throw new IdentityError();
      const trusted = memberSessions.verify(sessionToken);
      const member = memberStore.findByProviderIdentity?.(trusted.provider, trusted.providerUserId);
      if (!memberVisible(member)) return res.status(404).json({ message: '회원 정보를 찾을 수 없습니다.' });
      return res.json({ member: publicMember(member), providers: memberStore.listIdentities?.(member.id) ?? [], currentProvider: trusted.provider, recordOwnerIds: memberStore.recordOwnerIds?.(member.id) ?? [member.id], mergeAvailable: mergeAvailable() });
    } catch (error) { return next(error); }
  });
  app.delete('/v1/account/providers/:provider', async (req, res, next) => {
    try {
      const sessionToken = req.get('x-onaria-member-session');
      if (!sessionToken || !memberSessions) throw new IdentityError();
      const trusted = memberSessions.verify(sessionToken);
      const member = memberStore.findByProviderIdentity?.(trusted.provider, trusted.providerUserId);
      if (!memberVisible(member)) return res.status(404).json({ message: '회원 정보를 찾을 수 없습니다.' });
      const provider = req.params.provider;
      if (provider === trusted.provider) return res.status(409).json({ message: '현재 로그인에 사용 중인 계정은 연결 해제할 수 없습니다. 다른 계정으로 로그인한 뒤 다시 시도해 주세요.' });
      await requireAccountProof(req, member);
      const detachedIdentity = memberStore.listIdentityDetails?.(member.id)?.find(i => i.provider === provider);
      if (provider === 'apple') {
        if (!appleRevocation) throw new IdentityError(503);
        await appleRevocation({ authorizationCode: req.body?.appleAuthorizationCode, credential: req.body?.appleCredential,
          providerUserId: detachedIdentity?.providerUserId });
      }
      memberSessions.verify(sessionToken);
      if (!memberStore.detachIdentity?.(member.id, provider)) return res.status(404).json({ message: '연결된 계정을 찾을 수 없습니다.' });
      if (detachedIdentity) memberSessions.revokeIdentity?.(detachedIdentity);
      return res.status(204).end();
    } catch (error) {
      if (error.code === 'LAST_IDENTITY') return res.status(409).json({ message: error.message });
      return next(error);
    }
  });
  app.delete('/v1/auth/provider/session', (req, res, next) => {
    try {
      const sessionToken = req.get('x-onaria-member-session');
      if (!sessionToken || !memberSessions) throw new IdentityError();
      memberSessions.revoke(sessionToken);
      return res.status(204).end();
    } catch (error) { return next(error); }
  });
  app.delete('/v1/account', async (req, res, next) => {
    try {
      const sessionToken = req.get('x-onaria-member-session');
      if (!sessionToken || !memberSessions) throw new IdentityError();
      const trusted = memberSessions.verify(sessionToken);
      const member = memberStore.findByProviderIdentity?.(trusted.provider, trusted.providerUserId);
      if (!memberVisible(member)) return res.status(404).json({ message: '삭제할 회원 정보를 찾을 수 없습니다.' });
      await requireAccountProof(req, member);
      if ((memberStore.listIdentities?.(member.id) ?? []).includes('apple')) {
        if (!appleRevocation) throw new IdentityError(503);
        await appleRevocation({ authorizationCode: req.body?.appleAuthorizationCode, credential: req.body?.appleCredential,
          providerUserId: memberStore.listIdentityDetails?.(member.id)?.find(i => i.provider === 'apple')?.providerUserId });
      }
      memberSessions.verify(sessionToken);
      const ownerIds=memberStore.recordOwnerIds?.(member.id) ?? [member.id];
      if (ownerIds.length>1 && !deletionManifest?.recordMany) throw new IdentityError(503);
      if (deletionManifest?.recordMany) deletionManifest.recordMany(ownerIds);
      else deletionManifest?.record?.(member.id);
      const identities = memberStore.listIdentityDetails?.(member.id) ?? [trusted];
      // The stores may use separate databases. Revoke before deleting so a
      // session-store failure cannot delete the member while reporting failure.
      // A failed attempt may revoke some sessions; it never reports completion.
      for (const identity of identities) memberSessions.revokeIdentity?.(identity);
      memberSessions.revoke(sessionToken);
      if (!memberStore.deleteById?.(member.id)) return res.status(409).json({ message: '회원탈퇴를 완료하지 못했습니다. 로그인 상태를 확인한 뒤 다시 시도해 주세요.' });
      return res.status(204).end();
    } catch (error) {
      if (error instanceof IdentityError || error instanceof ZodError || error instanceof SyntaxError) return next(error);
      try { logger.error?.('account_deletion_failed', { status: 503 }); } catch { /* Never expose raw errors. */ }
      return res.status(503).json({ message: '회원탈퇴를 완료하지 못했습니다. 일부 로그인이 해제됐을 수 있으니 로그인 상태를 확인한 뒤 다시 시도해 주세요.' });
    }
  });
  app.post('/v1/mind/chat', async (req, res, next) => {
    try {
      metrics.chats += 1;
      if (appToken && req.get('authorization') !== `Bearer ${appToken}`) {
        return res.status(401).json({ message: '인증이 필요합니다.' });
      }
      const body = requestSchema.parse(req.body);
      const assessment = assessRequestCrisis(body);
      logSafetyAssessment(logger, assessment);
      webMetrics.safety(assessment);
      if (assessment.level > 0) {
        metrics.crises += 1;
        try { generate.usageLedger?.reserve({ sessionId: body.session.sessionId, taskType: 'crisis' }).finish({ provider: 'safety', tier: 'local' }); } catch { /* Never gate safety. */ }
        return res.json(crisisResponse(body.session.selectedEmotion, assessment));
      }

      // Shared app authentication above is unchanged. Per-member identity uses
      // a separate credential and is never inferred from body/session fields.
      const identityToken = req.get('x-soul-identity-token');
      let trustedIdentity = {};
      if (identityToken !== undefined) {
        if (!identity.verify) throw new IdentityError();
        trustedIdentity = await identity.verify(identityToken);
        if (!trustedIdentity || typeof trustedIdentity.userId !== 'string' || !trustedIdentity.userId
          || !['free', 'premium'].includes(trustedIdentity.plan)) throw new IdentityError();
      } else if (identity.required) throw new IdentityError();

      const agent = routeAgent({ requestedAgent: body.agentMode, userMessage: body.userMessage, verseLanguage: body.verseLanguage });
      // Client session IDs are not credentials. Keep anonymous chat stateless so
      // reusing another client's ID cannot retrieve their private context.
      const memorySummary = body.session.conversationMemory || body.session.conversationSummary || '';
      const result = responseSchema.parse(await generate(body, agent, memorySummary, trustedIdentity));
      if (result.riskLevel > 0 || result.stage === 'crisis') {
        metrics.crises += 1;
        webMetrics.safety({ level: Math.max(1, result.riskLevel), kind: 'response_crisis' });
        logSafetyAssessment(logger, { level: Math.max(1, result.riskLevel), kind: 'response_crisis' });
        return res.json(crisisResponse(body.session.selectedEmotion, { level: Math.max(1, result.riskLevel) }));
      }
      result.agent = agent.id;
      if (result.suggestedVerseId && !body.allowedVerseIds.includes(result.suggestedVerseId)) {
        result.suggestedVerseId = null;
        result.shouldOfferVerse = false;
      }
      if ((body.session.turnCount ?? 0) < 2) result.shouldOfferVerse = false;
      return res.json(result);
    } catch (error) { return next(error); }
  });

  app.use((error, _req, res, _next) => {
    if (error instanceof AccountMergeError) return res.status(error.status).json({code:error.code,message:error.message});
    if (error.code === 'PROFILE_SCHEMA_REQUIRED') return res.status(503).json({ message: '회원가입 서버 업데이트가 필요합니다. 잠시 후 다시 시도해 주세요.' });
    if (error instanceof IdentityError) return res.status(error.status).json({ message: error.message });
    // JSON parsing fails before a route or provider runs. Keep client errors
    // distinct from AI availability failures and never reflect parser details.
    if (error?.type === 'entity.too.large') {
      return res.status(413).json({ message: '요청 크기가 너무 큽니다. 내용을 줄여 다시 보내 주세요.' });
    }
    if (['charset.unsupported', 'encoding.unsupported'].includes(error?.type)) {
      return res.status(415).json({ message: '지원하지 않는 요청 인코딩입니다. UTF-8 JSON으로 보내 주세요.' });
    }
    if (error instanceof ZodError || error instanceof SyntaxError) {
      return res.status(400).json({ message: '요청 형식이 올바르지 않습니다.' });
    }
    if (error instanceof ZodError || error instanceof SyntaxError) {
      return res.status(400).json({ message: '요청 형식이 올바르지 않습니다.' });
    }
    const upstreamStatus = Number.isInteger(error?.status) ? error.status : 502;
    const status = [401, 403, 429].includes(upstreamStatus) ? upstreamStatus : 502;
    try { logger.error?.('request_failed', {
      status: upstreamStatus,
    }); } catch { /* Logging failures must not expose Express's raw error page. */ }
    const message = status === 429
      ? 'AI 사용량 또는 크레딧이 부족합니다.'
      : status === 401 || status === 403
        ? 'AI 인증 또는 모델 접근 권한을 확인해 주세요.'
        : 'AI 응답을 생성하지 못했습니다. 잠시 후 다시 시도해 주세요.';
    return res.status(status).json({ message });
  });
  return app;
}
