# ONARIA Master Product Plan & Launch Blueprint

> Living document. 기획 → 설계 → 개발 → 검증 → Preview → Release Candidate → 사용자 검증 → 운영배포 순서로 관리한다.
> 기준일: 2026-09-21
> 운영배포는 최종 Preflight와 사용자 승인 전에는 수행하지 않는다.

## 1. 제품 비전

ONARIA는 사용자의 현재 마음에서 출발해 **안전한 AI 마음대화 → 성경 말씀과 신앙적 성찰 → 작은 실천 → 기록과 재방문**으로 연결하는 신앙 기반 AI 마음관리 서비스다.

핵심 원칙:
- AI는 목회자·교회 공동체·의료인·심리치료사를 대체하지 않는다.
- 위기 신호에서는 일반 대화와 생성형 AI보다 현실의 안전과 도움을 우선한다.
- 성경/종교 자료는 출처·라이선스·맥락을 지킨다.
- 앱·홈페이지·Admin·API는 하나의 제품 언어와 상태를 공유한다.
- 현재 공개 범위는 성경/기독교 기반 경험에 집중한다.
- 새 기능보다 실제 사용자 흐름의 완결성과 안전성을 먼저 검증한다.

## 2. 제품 시스템

| 영역 | 주소/기술 | 역할 |
| --- | --- | --- |
| Mobile App | Flutter Android/iOS | 사용자 핵심 서비스 |
| Website | https://onaria.ai.kr | 소개, 신뢰/안전, 법적 안내, 설치 안내 |
| Admin | https://onaria.ai.kr/admin | 운영자 전용 관리 웹앱 |
| Production API | https://api.onaria.ai.kr | 앱/Admin API |
| Backend | Node.js | 대화, Safety, RAG, 회원/사용량, Admin API |
| Production host | ari-prod-01 / Ubuntu / nginx | Website + Admin + API + Backend + DB |

Website와 Admin은 같은 backend에서 제공하지만 UI와 접근 권한은 분리한다.

## 3. 핵심 사용자 여정

1. 감정 체크인
2. 감정 강도 선택
3. AI 마음대화
4. 현재 마음/욕구 이해
5. 말씀 연결
6. 작은 실천 선택
7. 마음카드 저장/공유
8. 성장 기록·7일 여정·알림·십자가 미니게임으로 재방문

Safety Gate는 모든 생성형 AI 흐름보다 우선한다.

## 4. App Storyboard

### APP-01 감정 체크인
- 16개 기본 감정 카드
- 기타 직접 입력
- 감정 강도 1~10
- 사용 빈도 높은 감정은 위쪽으로 정렬
- 기타 입력 키워드가 동일 기기에서 30회 이상 반복되면 새 동적 감정카드 후보로 승격
- 동적 카드 선택 시 원래 직접 입력 문구를 대화 맥락에 전달
- 상태: CODE 구현 브랜치 #33 / TEST·REAL 재검증 필요

### APP-02 AI 마음대화
- 감정/강도/직접 입력을 반영
- 질문별 답변 예시 제공
- 상황→생각→욕구→말씀→실천으로 연결
- 통합 인사이트는 반복 문구를 줄이고 감정·욕구·신앙·행동을 조합하는 방향
- 상태: 구현됨 / 실제 품질 검증 계속

### APP-03 말씀 연결
- 승인된 verse ID만 노출
- 장절·본문·묵상 질문 연결
- 근거 없는 성경 인용/교리 생성 금지
- 한국어 KRV와 출시 가능한 승인 자료 범위 우선
- 개발 참고용 영문 자료는 정식 출시 노출 여부 별도 Gate
- 상태: 구현·검증 중

### APP-04 작은 실천
- 감정별 행동 제안
- 임상심리 기반 안정화 행동
- 사용자가 선택/변경 가능
- 상태: 구현됨 / 문구·UX 검증

### APP-05 마음카드·기록
- 현재 마음/말씀/묵상/실천/통합 인사이트 저장
- 기기 저장
- 삭제
- 이미지 공유
- 상태: 구현됨 / 실기기 공유 검증 필요

### APP-06 재방문
- 7일 마음의 여정
- 알림
- 성장 기록
- 저장된 카드
- 십자가 미니게임
- 상태: 구현됨 / 실기기 검증 필요

### APP-07 십자가 미니게임
- 6개 빛 조각: 평안·희망·사랑·은혜·용기·용서
- 시작/중지/재개/재시작/완료
- 성경 말씀 카드와 별도로 '오늘의 사유' 표시
- 365개의 ONARIA 자체 사유 템플릿을 날짜별로 회전
- 철학적 주제를 참고하되 현대 번역 명언을 그대로 인용하지 않음
- 상태: CODE 구현 브랜치 #33 / TEST·REAL 재검증 필요

### APP-08 메뉴/법적 안내
메뉴 하단:
1. 개인정보 처리방침
2. 개인정보 수집·이용 / 국외이전 안내
3. 서비스 이용약관
4. 오픈소스 라이선스
5. 앱 버전/빌드 번호 — 항상 맨 아래

- 상태: CODE 구현 PR #31 / 정식 법적 문구 확정 필요

### APP-09 앱 식별자/아이콘
- Android applicationId/namespace: `com.onaria.app`
- iOS bundle ID: `com.onaria.app`
- iOS test bundle: `com.onaria.app.RunnerTests`
- 런처 아이콘: 밝은 ONARIA 방향으로 통일
- 상태: ID는 PR #32, 밝은 아이콘 원본/생성 스크립트는 PR #33
- 남음: Android/iOS 실제 생성 자산 및 Release build 확인

## 5. Website Storyboard

### WEB-01 Home
- 브랜드: “모든 마음에는 저마다의 길이 있습니다.”
- 현재 성경/기독교 기반 제품 정체성 명확화
- 감정 체크인 → AI 마음대화 → 말씀 → 작은 실천
- Safety/Privacy/신뢰 원칙
- 상태: 구현됨 / 반응형·외부 REAL 회귀 필요

### WEB-02 About / Services
- ONARIA 목적과 한계
- AI/전문가/교회 비대체 원칙
- 현재 제공 범위와 준비 중 기능을 과장 없이 표시

### WEB-03 Privacy / Terms
- /privacy
- /terms
- 현재 구현 구조를 설명하는 초안 존재
- 정식 공개 전 운영주체·문의처·보유기간·외부 AI 제공·국외이전 여부 확정 필요

## 6. Admin Storyboard

Admin은 Website와 같은 서버에 있지만 **/admin 경로의 별도 운영 웹앱**이다.

### ADM-01 Dashboard
- 서버/서비스 상태
- 대화 요청
- 가입 회원
- Safety 감지
- AI usage/cost

### ADM-02 Users
- 최근 가입 회원
- 전화번호 마스킹
- 개인정보 최소 노출

### ADM-03 AI Usage & Cost
- AI 요청/호출
- 입력/캐시/출력 토큰
- 예상 비용
- 세션·회원당 평균
- fallback/모델 tier 비율

### ADM-04 Safety
- 위험 분류/등급/횟수/최근 시각
- 대화 원문 기본 비표시

### ADM-05 Content / Analytics
- 콘텐츠 검토 상태
- 전통/라우팅 사용량
- 운영 지표

### ADM-06 System / API Settings
- OpenAI API 설정
- 브라우저 저장 금지
- CSRF
- no-store
- HTTPS 전용

### ADM-07 개인정보 보호
- 고객정보 최소 표시
- 대화 원문 기본 비표시
- 관리자 인증정보/API key 브라우저 저장 금지
- DB 대량 추출·삭제·마이그레이션은 승인 절차 필요
- 메뉴 하단: 개인정보 처리방침 → 이용약관 → 공식 홈페이지 → Admin 버전
- 상태: CODE 구현 PR #31 / TEST·REAL 회귀 필요

## 7. Safety 설계

위기 요청 불변조건:
- Psychology model call 증가량 0
- Religion model call 증가량 0
- OpenAI client 생성 증가량 0
- 일반 생성형 응답 대신 고정 local crisis response
- 한국 기준 109/112/119 연결 안내
- 실제 위치/구조 요청을 했다고 표현하지 않음

Safety는 앱, backend, Admin 집계가 같은 정책을 사용해야 한다.

## 8. 데이터/개인정보 설계

- 마음카드: 일부 기기 로컬 저장
- 감정카드 사용 빈도/기타 키워드 승격: 현재 PR #33 기준 기기 로컬 SharedPreferences
- 회원 DB와 AI usage DB는 운영 서버
- 관리자 화면은 식별정보 최소 표시
- 비밀값/API key는 Git·앱 번들·브라우저 저장소에 넣지 않음
- 실제 수집·보유·삭제·국외이전 정책은 정식 개인정보 처리방침과 일치해야 함

## 9. App ↔ API ↔ Website ↔ Admin 호환 규칙

1. 제품 용어를 동일하게 사용한다.
2. 앱 release는 `https://api.onaria.ai.kr`만 사용한다.
3. localhost/raw IP/구 Cafe24 주소를 release에서 허용하지 않는다.
4. Admin 인증/CSRF/cache 정책은 앱 사용자 API와 분리 검증한다.
5. 공개 Website는 secret/운영 내부정보를 노출하지 않는다.
6. 사용자에게 보이는 기능 상태는 실제 구현/검증 상태와 일치해야 한다.
7. 변경은 CODE / TEST / REAL / USER 증거를 분리한다.
8. 운영 배포는 최종 Preflight와 사용자 승인 이후에만 한다.

## 10. 현재 Git 작업 구조

- PR #31: 법적 메뉴 + 버전정보 + Admin 개인정보 보호
- PR #32: production app identifier `com.onaria.app`
- PR #33: adaptive emotion cards + 365 Cross Light reflections + 밝은 아이콘 소스
- PR #20: 현재 운영 인프라 문서 동기화
- Issue #21: GitHub Actions backend-tests runner 문제
- Issue #22: Launch Gate
- Issue #23: legacy package/bundle ID — #32에서 교체 작업 진행
- Issue #24~#29: Infra/Web/Admin/Backend/AI/Safety/Release/최종 QA agent 검증 큐

PR은 아직 병합/운영배포 완료로 간주하지 않는다.

## 11. 출시 전 필수 Gate

### CODE
- [ ] #31~#33 최종 diff 검토
- [ ] stale 문서/legacy `com.example...` 잔존 점검
- [ ] 영문 NIV 개발 참고 자료의 production 노출 차단/범위 확정
- [ ] 법적 문서 최종 사업자 정보 반영

### TEST
- [ ] backend tests PASS
- [ ] Flutter tests PASS
- [ ] flutter analyze PASS
- [ ] Android debug build PASS
- [ ] Android release/AAB build PASS
- [ ] iOS simulator compile PASS
- [ ] Website/Admin browser E2E PASS
- [ ] 365 reflection unique/count test PASS
- [ ] adaptive emotion promotion/order test PASS

### REAL
- [ ] production /health
- [ ] 정상 AI 마음대화 실제 왕복
- [ ] fallback/local과 실제 provider 성공 구분
- [ ] crisis 요청 provider call 증가량 0
- [ ] Admin HTTPS/login/CSRF/no-store
- [ ] Website mobile/tablet/desktop
- [ ] Android 실기기 전체 핵심 흐름
- [ ] iOS simulator 및 가능 시 실기기
- [ ] App Links/Associated Domains는 런칭 후 기능 활성화 정책과 충돌 없는지 확인

### USER
- [ ] 감정 선택/기타 입력/강도
- [ ] AI 대화
- [ ] 말씀
- [ ] 실천
- [ ] 마음카드 저장/공유
- [ ] 7일 여정
- [ ] 알림
- [ ] 십자가 미니게임
- [ ] 메뉴/법적 문서/버전
- [ ] 전체 흐름에서 막힘/중복/오해 문구 기록

## 12. Release / Store 준비

### Android
- applicationId: `com.onaria.app`
- AAB release build
- 정식 signing
- Play App Signing/업로드키 결정
- versionName/versionCode 확인
- production API 확인
- Data safety / 개인정보처리방침 URL 준비

### iOS
- bundle ID: `com.onaria.app`
- Apple Developer App ID
- signing/team/provisioning
- Associated Domains
- App Store Connect metadata
- Privacy Nutrition Label/개인정보 답변
- production API 확인

## 13. 최종 Preflight

운영 반영 직전에 한 번만 전체 확인:
- Git status/diff/secret scan
- merge 대상 SHA
- CI 결과
- Android/iOS release metadata
- DNS/TLS/nginx
- backend service
- DB 경로/백업/rollback
- Website/Admin/API
- Safety
- 개인정보/약관
- store metadata

이 보고를 사용자에게 제시한 뒤 최종 승인을 받고 운영 변경·재시작·배포를 실행한다.

## 14. 다음 실행 순서

1. PR #31~#33 통합 검토 및 자동 테스트
2. CI runner 문제 #21 해결/우회 없이 정상 PASS 근거 확보
3. Android/iOS release 식별자·서명·빌드 검증
4. 법적 문서 사업자 정보 확정
5. Production API/Admin/Website REAL 점검
6. 앱 전체 기능 QA
7. 사용자 휴대폰 최종 USER 테스트
8. Store 등록/업로드 준비
9. 최종 Preflight
10. 사용자 승인 후 운영 배포
