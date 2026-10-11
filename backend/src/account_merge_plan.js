// Read-only planning only. This module never authenticates, authorizes or executes a merge.
// Inputs must be a server-side snapshot; never use a client-supplied ownership map.
const providers = new Set(['apple', 'google', 'naver', 'kakao']);
export function planAccountMerge({ members, identities, targetId, sourceIds }) {
  const validId = id => Number.isSafeInteger(id) && id > 0;
  if (!Array.isArray(members) || !Array.isArray(identities) ||
      !validId(targetId) || !Array.isArray(sourceIds) || !sourceIds.length ||
      sourceIds.some(id => !validId(id) || id === targetId) ||
      new Set(sourceIds).size !== sourceIds.length) throw new Error('INVALID_PLAN_INPUT');
  const memberIds = members.map(m => m.id);
  if (memberIds.some(id => !validId(id)) || new Set(memberIds).size !== memberIds.length)
    throw new Error('INVALID_MEMBER_SNAPSHOT');
  const selected = new Set([targetId, ...sourceIds]);
  if ([...selected].some(id => !memberIds.includes(id))) throw new Error('MEMBER_NOT_FOUND');
  const byProvider = new Map(), seen = new Map();
  for (const identity of identities) {
    const { memberId, provider, providerUserId } = identity;
    if (!memberIds.includes(memberId) || !providers.has(provider) ||
        typeof providerUserId !== 'string' || !providerUserId || providerUserId.length > 200)
      throw new Error('INVALID_IDENTITY_SNAPSHOT');
    const key = JSON.stringify([provider, providerUserId]);
    if (seen.has(key)) throw new Error('DUPLICATE_IDENTITY_SNAPSHOT');
    seen.set(key, memberId);
    if (!selected.has(memberId)) continue;
    if (byProvider.has(provider) && byProvider.get(provider) !== providerUserId)
      throw new Error('SAME_PROVIDER_ACCOUNT_CONFLICT');
    byProvider.set(provider, providerUserId);
  }
  for (const memberId of selected) {
    if (!identities.some(i => i.memberId === memberId)) throw new Error('MEMBER_WITHOUT_IDENTITY');
  }
  return {
    version: 1, status: 'PLAN_ONLY_NOT_AUTHORIZED',
    targetId, sourceIds: [...sourceIds].sort((a,b) => a-b),
    providers: [...byProvider.keys()].sort(),
    preservedRecordOwnerIds: [...selected].sort((a,b) => a-b),
    requiredProofMemberIds: [...selected].sort((a,b) => a-b),
    guestAndUnclaimedRecords: 'EXCLUDED',
    sourceMemberDeletion: false,
    requirements: [
      'fresh server-verified proof for every member bound to one merge attempt',
      'explicit user confirmation of the exact target and sources',
      'expiring one-use merge attempt with replay protection',
      'snapshot recheck under transaction before identity reassignment',
      'revoke all old sessions before issuing a canonical member session',
      'authenticated record-owner mapping before local import',
      'copy and verify records; never overwrite conflicting record ids or delete originals',
      'idempotent operation and durable audit receipt without provider credentials',
      'resolve deletion and backup semantics for all preserved owner ids before activation'
    ]
  };
}
