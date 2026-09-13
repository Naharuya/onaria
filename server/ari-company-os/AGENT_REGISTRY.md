# ARI Agent Registry & Deduplication Policy

## 목적
신규 Agent를 만들기 전에 기존 Agent를 먼저 조사하고, 기능이 겹치면 새 Agent를 만들지 않고 기존 Agent를 재사용·확장한다.

## Agent 계층
### A. Product Runtime Agents — 이미 존재, 재생성 금지
이들은 ONARIA/SoulBible 사용자 응답 경로에서 실제로 동작하는 제품 Agent다.

- `backend/src/agents/safety_agent.js` — 위기/Safety
- `backend/src/agents/psychology_agent.js` — 심리 반영
- `backend/src/agents/conversation_orchestrator.js` — 제품 대화 orchestration
- `backend/src/agents/religion_router.js` — 종교 routing
- `backend/src/agents/religious_integrity_agent.js` — 종교/심리 무결성 검증
- `backend/src/agents/response_integrator.js` — 최종 통합
- `backend/src/agents/citation_validator.js` / `citation_grounding.js` — 인용 검증
- `backend/src/agents/religions/protestant_agent.js`
- `backend/src/agents/religions/catholic_agent.js`
- `backend/src/agents/religions/buddhist_agent.js`
- `backend/src/agents/religions/jewish_agent.js`
- `backend/src/agents/religions/islamic_agent.js`
- `backend/src/agents/religions/hindu_agent.js`
- `backend/src/agents/religions/confucian_agent.js`

규칙: Safety/Psychology/Religion/Integration/Citation 기능은 ARI Company OS에 동일 Agent를 새로 만들지 않는다. 자동화 계층은 이 Agent들을 테스트·호출·관찰할 뿐 대체하지 않는다.

### B. Existing Development Specialist — 재사용 우선
- `.github/agents/rami-audio-manager.agent.md` — RAMI 오디오 전문 Agent

규칙: RAMI audio/record/playback/card-sound 업무가 필요하면 신규 Audio Agent를 만들지 않고 이 Agent를 canonical owner로 사용한다.

### C. ARI Company OS Agents — 신규이지만 제품 Runtime Agent와 겹치지 않는 운영 계층
- `ari-main-manager` — 회사/프로젝트 작업 orchestration
- `product-manager` — 사용자/지표 기반 개발 우선순위
- `coding-agent` — 승인된 Task 구현
- `repair-agent` — 검증 실패의 제한적 수정
- `verification-core` — 공통 독립 검증
- `growth-agent` — 유입/활성/리텐션 병목 분석
- `customer-research-agent` — 사용자 피드백 군집화
- `competitor-agent` — 경쟁사 변화 분석
- `government-grant-agent` — 지원사업 탐색/역산 일정
- `finance-agent` — 비용/매출/unit economics
- `release-manager` — SERVER_PASS/CI/DEVICE_PASS/RELEASE_APPROVED gate

## 신규 Agent 생성 전 의무 절차
1. 아래 위치를 먼저 검색한다.
   - `backend/src/agents/`
   - `backend/src/agents/religions/`
   - `.github/agents/`
   - `server/ari-company-os/config/agents.yaml`
   - 각 프로젝트의 `.ari/` 및 server 등록 Agent
2. 후보 Agent의 mission/input/output/권한을 기존 Registry와 비교한다.
3. 기능 중복도가 높으면 새 Agent 생성 금지.
4. 기존 Agent로 해결 가능하면 기존 Agent에 capability/profile/task type을 추가한다.
5. 같은 기능이지만 프로젝트별 규칙만 다르면 Agent를 복제하지 않고 project profile을 사용한다.
6. 정말 새로운 책임일 때만 canonical ID를 하나 추가한다.

## 중복 판정 기준
다음 중 2개 이상이 겹치면 기본적으로 duplicate candidate다.
- 같은 입력 데이터
- 같은 최종 산출물
- 같은 코드/업무 영역
- 같은 의사결정 권한
- 같은 성공 KPI

## 금지 예시
- `safety-review-agent` 신설: 기존 `safety_agent`와 `verification-core` 조합으로 처리
- `psychology-review-agent` 신설: 기존 `psychology_agent` + integrity/verification으로 처리
- `bible-agent` 신설: 기존 Religion/RAG/citation 계층 재사용
- `rami-audio-agent-v2` 신설: 기존 RAMI Audio Manager 확장
- 프로젝트마다 `verification-agent` 복제: 공통 `verification-core` + `.ari/verification.yaml`
- 프로젝트마다 `coding-agent` 복제: 공통 Coding Agent + 프로젝트 context/profile

## 이름 규칙
신규 Agent ID는 Registry에서 유일해야 하며 이름만 다른 동일 역할 Agent를 허용하지 않는다.
예: `qa-agent`, `test-agent`, `verification-agent`를 따로 만들지 않고 canonical `verification-core` 하나만 사용한다.

## Main Manager 의무
새 Agent 생성 요청을 받으면 먼저 `REUSE_EXISTING`, `EXTEND_EXISTING`, `NEW_AGENT_REQUIRED` 중 하나를 판정한다.
- `REUSE_EXISTING`: 기존 Agent 그대로 사용
- `EXTEND_EXISTING`: capability/profile만 추가
- `NEW_AGENT_REQUIRED`: 중복 없음이 확인된 경우에만 생성

## 현재 결론
현재 SoulBible의 Safety/Psychology/Religion/Integration/Citation Agent는 이미 구현되어 있으므로 Company OS에서 재생성하지 않는다. Company OS는 개발·검증·성장·사업 운영의 상위 orchestration 역할만 담당한다.
