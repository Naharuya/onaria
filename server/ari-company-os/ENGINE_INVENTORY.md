# Execution Engine v1 Inventory

Baseline: origin/automation/server-agent-platform-v0.1 `8951fce`; prior Mac installation changes preserved and backed up before edits.
Read: AGENT_REGISTRY.md (canonical location: server/ari-company-os), root AGENT_OWNERSHIP_POLICY.md, both SERVER_* specs, OS source/config/profiles, backend runtime agents, .github/agents/rami-audio-manager.agent.md, RAMI audio service, GitHub Issues #6/#7 including #7 ownership/registry corrections.

| Existing owner | Decision | Existing implementation / extension needed |
|---|---|---|
| ari-main-manager | EXTEND_EXISTING | Existing queue loop; add scheduler, registry-first dispatch, followups and daily report capability |
| coding-agent | EXTEND_EXISTING | Existing registered role; add approval, per-task isolated worktree, focused tests and verification handoff |
| repair-agent | EXTEND_EXISTING | Existing Codex proposal adapter; move repair orchestration out of Verification Core |
| verification-core | EXTEND_EXISTING | Existing runner/debounce/profiles; independent result, secret scan, stage ordering and revision checks |
| product-manager | EXTEND_EXISTING | Existing role; turn explicit evidence/criteria into unapproved development tasks |
| customer-research-agent | EXTEND_EXISTING | Contract and KST scheduler; source not connected |
| growth-agent | EXTEND_EXISTING | Contract and KST scheduler; source not connected |
| competitor-agent | EXTEND_EXISTING | Contract and KST scheduler; source not connected |
| government-grant-agent | EXTEND_EXISTING | Pre-founder contract, KST scheduler/deadline capability; source not connected |
| finance-agent | EXTEND_EXISTING | Contract and KST scheduler; source not connected |
| release-manager | EXTEND_EXISTING | Existing gate; add matching revision and Test Build gate |
| Safety, Psychology, Conversation Orchestrator, Religion Router, Religious Integrity, Response Integrator | REUSE_EXISTING | backend/src/agents; retain product runtime and verify existing tests |
| Citation Validator / Grounding | REUSE_EXISTING | backend/src/agents/citation_*; retain canonical implementation |
| Seven Religion Specialists | REUSE_EXISTING | backend/src/agents/religions/*_agent.js; no company-layer copies |
| RAMI Audio Manager | REUSE_EXISTING | .github/agents/rami-audio-manager.agent.md; existing specialist owner via coding capability |

NEW_AGENT_REQUIRED: none. Main Manager daily reporting is a capability, not another agent.
Existing aliases qa-agent/test-agent/verification-agent resolve to verification-core.
Missing at inventory time: formal task state machine/dedupe; scheduler; runtime registry resolver; independent verification; Test Build release gate; coding execution workflow; persistent followup transaction; complete execution contracts.
Old spec names Test/Review/Build/Engineering/Legal agents do not authorize new identities: current Registry v2 and explicit user instructions take precedence. Test/build review capabilities stay in Verification Core; legal/high-risk events escalate immediately.
