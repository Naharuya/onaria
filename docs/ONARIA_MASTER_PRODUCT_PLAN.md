# ONARIA Master Product Plan & Storyboard

> Living document. 개발·검증·배포와 함께 계속 갱신한다.
> 상태: 기획 → 개발중 → 테스트중 → Preview → 완료 → 운영배포

## 1. 제품 비전
ONARIA는 사용자의 현재 마음에서 출발해 안전한 AI 마음대화, 성경 말씀과 신앙적 성찰, 작은 실천과 기록으로 연결하는 신앙 기반 AI 마음관리 서비스다.

핵심 원칙:
- AI는 목회자·교회 공동체·의료인·심리치료사를 대체하지 않는다.
- 위험 신호에서는 일반 대화보다 현실의 안전과 도움을 우선한다.
- 성경/종교 자료는 출처와 맥락을 존중한다.
- 앱·홈페이지·Admin·API는 하나의 제품 언어와 상태를 공유한다.
- 현재 출시 경험은 성경 기반이며, 7개 전통은 장기 확장 구조로 구분한다.

## 2. 제품 시스템
- Mobile App: Flutter Android/iOS
- Production API: https://api.onaria.ai.kr
- Website: https://onaria.ai.kr
- Admin: https://onaria.ai.kr/admin
- Backend: Node.js
- Website/Admin: 동일 backend에서 제공
- Public website 변경 때문에 Flutter production API를 변경하지 않는다.

## 3. 핵심 사용자 여정
감정 체크인 → AI 마음대화 → 현재 마음 이해 → 말씀 연결 → 작은 실천 → 마음카드/기록 → 재방문

Safety Gate는 모든 AI 흐름보다 우선한다.

## 4. App Storyboard

### SB-APP-001 감정 체크인
- 목적: 현재 감정과 강도를 부담 없이 인식
- 입력: 감정 선택/직접 입력, 강도
- 다음: AI 마음대화
- 상태: 구현됨 / 지속 개선

### SB-APP-002 AI 마음대화
- 목적: 단정하지 않는 질문으로 상황과 생각을 돌아봄
- 연동: Production API / Safety
- 다음: 말씀 연결
- 상태: 구현·검증 중

### SB-APP-003 말씀 연결
- 목적: 현재 감정·상황과 관련된 성경 말씀과 성찰 연결
- 원칙: 근거 없는 인용 금지, 감정을 억누르는 정답식 사용 지양
- 상태: 구현·검증 중

### SB-APP-004 작은 실천
- 목적: 오늘 가능한 한 걸음 제안/선택
- 다음: 마음카드/기록
- 상태: 구현됨 / 개선 중

### SB-APP-005 마음카드·기록
- 목적: 대화에서 발견한 마음과 실천을 다시 볼 수 있게 정리
- 저장: 일부 기록 기기 저장
- 상태: 구현됨 / 개선 중

## 5. Website Storyboard

### SB-WEB-001 Hero
- 브랜드 문장: “모든 마음에는 저마다의 길이 있습니다.”
- 제품 문장: “마음이 힘든 순간, 말씀과 다시 연결됩니다.”
- 설명: 안전한 AI 마음대화 → 성경 말씀 → 작은 실천
- CTA: ONARIA 알아보기 / 안전 원칙 보기
- 디자인: 기존 네이비·아이보리 브랜드 톤과 기존 emblem 유지, 광원·선명도 고도화
- 상태: Preview 개발중

### SB-WEB-002 Why ONARIA
- 문제: 마음의 어려움은 주일만 기다려주지 않음
- 역할: 신앙적 답을 서둘러 강요하기보다 마음을 먼저 듣고 말씀·공동체로 연결
- 상태: 개발중

### SB-WEB-003 How it works
- 감정 체크인 → AI 마음대화 → 말씀 연결 → 작은 실천·기록
- 앱 용어와 일치
- 상태: 개발중

### SB-WEB-004 Safety & Trust
- Safety First
- Scripture Integrity
- Privacy by Design
- Human-centered AI
- 교회/목회자/전문가 비대체 원칙
- 상태: 개발중

### SB-WEB-005 Closed Beta / Church PoC
- 핵심 기능·Safety 검증 상태를 과장 없이 공개
- 초기 사용자 및 교회 PoC 방향
- 상태: 개발중

### SB-WEB-006 7 Paths
- 장기 확장 비전
- 현재 출시 경험과 혼동되지 않도록 하단 배치
- 상태: 기존 구현 유지 / 메시지 검토

## 6. Admin Storyboard

### SB-ADM-001 Dashboard
- 운영 상태와 핵심 지표
- 상태: 구현됨 / 연동 검증 필요

### SB-ADM-002 Users
- 사용자 운영 화면
- 상태: 구현됨 / 개인정보 원칙 검증 필요

### SB-ADM-003 AI Usage & Cost
- AI 사용량·비용·처리 상태
- 상태: 구현됨 / 운영 검증 필요

### SB-ADM-004 Safety Operations
- 위험 수준/분류/집계 중심
- 대화 원문 기본 노출 지양
- 상태: 연동 검증 필요

## 7. App ↔ API ↔ Website ↔ Admin 호환 규칙
1. 제품 용어를 동일하게 사용한다.
2. Website는 Production API 주소를 임의 변경하지 않는다.
3. Admin 변경은 앱 인증/대화 API와 분리 검증한다.
4. 공개 Website는 운영 비밀정보를 노출하지 않는다.
5. 사용자에게 보이는 출시 상태는 실제 구현/검증 상태와 일치해야 한다.
6. 변경 후 모바일/태블릿/데스크톱 및 핵심 API 회귀 테스트를 수행한다.

## 8. 현재 개발: Website Launch Alignment
- Branch: feat/launch-website-christian-positioning
- Draft PR: #17
- 목표: 기존 ONARIA 디자인을 고도화하면서 현재 기독교/성경 기반 제품 정체성을 명확히 전달
- 변경 경계: /admin, /v1, 인증, CSRF, DB, AI Router, Flutter production API는 변경하지 않음
- Preview: V3 제작
- 운영배포: 미실행
- 외부 이슈: www.onaria.ai.kr TLS hostname mismatch는 2026-09-21 현재 새 운영 서버(1.201.113.102, Ubuntu, nginx)에서 Let’s Encrypt SAN 및 HTTPS 200을 확인해 해결 상태로 기록

## 9. QA / 완료 조건
Website:
- 기존 E2E 구조/링크/SEO PASS
- 390 / 768 / 1440px bounds PASS
- CTA 실제 동작
- 기존 emblem 밝기 개선 후 접근성/가독성 확인
- Admin/API 회귀 없음
- Preview 승인 후 운영 배포
- onaria.ai.kr 외부 200 및 자산 정상
- www TLS: 인증서 SAN과 HTTPS 200 확인 완료. canonical 정책(200 유지 또는 root redirect)은 별도 제품/SEO 결정으로 관리

## 10. 개발 이력
### 2026-09-21
- Master Product Plan/Storyboard 시작
- Website launch positioning 브랜치 및 Draft PR #17 생성
- Hero/Why/말씀 연결/Safety/Closed Beta 메시지 정렬
- 기존 디자인 고도화 CSS 반영
- Preview V1 → V2 → V3 제작
- 다음: 실제 emblem 밝기 개선을 Git 브랜치에 반영, E2E/회귀 테스트, Preview 갱신

## 11. 다음 개발 큐
1. Website V3 실제 코드와 Preview 일치
2. 기존 ONARIA emblem 밝기 개선
3. Website E2E 및 반응형 검증
4. 앱/Website 용어 최종 일치 검사
5. Admin/API 회귀 검사
6. Preview 최종 확인
7. PR ready 전환 및 병합/배포 조건 확인
8. 운영 배포 후 실제 외부 검증
