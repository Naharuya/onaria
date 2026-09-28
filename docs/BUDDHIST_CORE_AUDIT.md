# Buddhist 기능 통합 — 1단계 코드 점검

점검일: 2026-09-28. 목적은 현재 Christian 구현 중 재사용할 부분과 종교별 경계를 확인하고,
다음 구현을 작은 단위로 확정하는 것이다. 이 단계에서는 실행 코드를 변경하지 않는다.
과거 설치·테스트 보고를 현재 검증 결과로 대신하지 않는다.

## 기준 상태

- 저장소: ONARIA, Flutter + Node/Express. Branch: `feature/onaria-buddhist`.
- HEAD: `5f6031e3328473f337d8a8b7abff801ae1a6763f`.
- 기존 tracked 수정 14개 및 Buddhist/Ollama 등 미추적 작업이 있는 dirty 상태를 보존했다.
- origin/main fetch 완료. HEAD 고유 53커밋, origin/main 고유 2커밋이다.
  원격의 추가 2개는 ARI compliance 문서 커밋이다. 자동 merge/reset/stash는 하지 않았다.
- 기존 Christian 버전은 pubspec 기준 0.4.1+6, Buddhist는 0.1.0+1.
- Christian package는 `com.onaria.app`, Buddhist는 `com.onaria.buddhist`다.
- Buddhist 전용 키 생성·사용은 사용자가 별도로 승인한 기존 지침의 예외다.
  이후 업데이트도 같은 전용 키를 유지하며 키·비밀번호는 문서/Git에 기록하지 않는다.
- 이번에는 기기, 운영 API, 사용자 저장 파일, DB 본문을 읽지 않았다. 저장 위치는 소스만 확인했다.

## 기능 비교와 코드 근거

표의 “있음”은 코드가 있다는 의미이며 운영 검증 또는 모든 요구사항 완료를 뜻하지 않는다.
이전 대화의 20~30%는 대략적인 설명이었으며, 가중치가 정해진 측정 지표가 아니다.

| 기능 | Christian의 현재 코드 | Buddhist의 현재 코드 | 재사용 판단 |
|---|---|---|---|
| Safety | 기존 import 경로가 공통 패키지를 export | 같은 감지기 및 고정 로컬 응답 사용 | 이미 공유. 최우선 불변 조건 |
| 감정 체크인 | 16개 감정, 강도, 직접 입력, 선택 빈도 | 5개 선택과 자유 입력, 강도 모델 없음 | 데이터 모델부터 공유하고 저장 통계는 나중에 연결 |
| 대화 상태 | 상황·생각·필요·말씀·실천·요약, 턴 제한 | 입력마다 고정 안내와 검색, 대화 이력/단계 없음 | 종교 중립 상태와 종교별 매핑을 먼저 정의 |
| AI/심리 | API client, 로컬 fallback, backend Psychology/Religion pipeline | 네트워크·AI 호출 없음 | 후속 단계에서 별도 dev 경로와 가짜 클라이언트로 검증 |
| 자료 검색 | BibleVerse/VerseRepository와 Bible asset | 전용 Mock Provider, 합성 문장 2개 | 구현은 Pack에 유지하고 공통 인터페이스만 공유 |
| 마음카드 | 감정·강도·구절·실천·요약 등 상세 레코드 | Provider ID만 저장, 재조회해 표시 | 공통 카드 모델과 출처 참조를 설계. Christian schema 보존 |
| 저장/복원 | 카드 목록·삭제·손상 레코드 처리 | SharedPreferences의 ID 목록·중복 제거 | 저장 인터페이스/오류 처리를 공유하고 키는 분리 |
| 성장 | 카드 통계, journey, achievements | 저장 카드 수와 목록 | 제어 로직 일부 재사용 가능, 말씀 및 여정 콘텐츠는 분리 |
| 가입/로그인 | 교회명 필수 회원가입, social 버튼은 ‘준비 중’ | 없음 | 완성된 로그인 모듈로 간주하지 않는다. 별도 요구 분석 필요 |
| 클라우드 기록 | 마음카드는 기기 로컬 저장, backend 메모리는 프로세스 Map | 기기 로컬 저장 | 계정 간 기록 동기화가 완성됐다고 간주하지 않는다 |
| 공유 | 카드 렌더링·미리보기·native share | 없음 | 이미지/전달 동작 공유, 말씀/초대 문구는 Pack으로 분리 |
| 음성 | ConversationPage 내 STT/TTS와 생명주기 처리 | 없음 | gateway/controller 추출 후 종교별 문구 주입 |
| 알림 | 스케줄·권한·복구, 오늘/저장한 말씀 문구 | 없음 | 스케줄 로직 공유 가능, 라벨·목적지는 분리 |
| 게임 | Cross Light와 종교 관련 성찰 데이터 | 없음 | 당장 포팅하지 않음. Buddhist 적용 범위 별도 결정 |
| Admin | 인증·CSRF·회원 마스킹·설정 | 읽기 전용 개발 상태 | 운영 Admin에 연결하지 않고 dev 역할/데이터 범위부터 정의 |
| 테스트/CI | root Flutter, backend, Web workflows | 별도 Flutter 및 Web 테스트는 로컬 명령 | 별도 앱 테스트·빌드를 CI에 명시적으로 추가해야 함 |

근거 파일:

- [Christian 체크인](../lib/features/check_in_page.dart), [대화 모델](../lib/src/conversation/conversation_models.dart), [상태 머신](../lib/src/conversation/conversation_machine.dart), [대화 화면](../lib/features/conversation_page.dart)
- [카드 저장](../lib/app/mind_card_store.dart), [감정 통계](../lib/app/emotion_card_store.dart), [성장 화면](../lib/features/growth_page.dart)
- [가입 화면](../lib/features/signup_page.dart), [회원 계약](../backend/src/member_schema.js), [메모리 저장](../backend/src/memory_store.js)
- [공유 카드](../lib/engagement/sharing/share_card.dart), [알림](../lib/engagement/notifications/reminder_controller.dart), [성장 제어](../lib/engagement/engagement_controller.dart)
- [Buddhist 화면](../apps/buddhist/lib/main.dart), [Buddhist 세션](../apps/buddhist/lib/session.dart), [공통 Safety](../packages/onaria_core/lib/onaria_core.dart), [Mock Provider](../packages/onaria_buddhist_pack/lib/onaria_buddhist_pack.dart)
- [Admin 인증](../backend/src/admin_auth.js), [Android QA](../.github/workflows/build-android.yml), [Web QA](../.github/workflows/onaria-web.yml)

## 재사용 경계와 우선순위

1. **P0 경계 유지:** Safety는 Provider/모델 호출보다 먼저 실행한다. 위기 상태는 일반 입력으로
   낮추지 않는다. 이관 과정에서 Christian의 기존 동작을 바꾸지 않는다.
2. **P1 첫 대상:** EmotionType이 종교와 무관하지만 ConversationStage 및 verse 필드와 같은 파일에 있다.
   감정 모델을 독립적으로 분리하면 Bible/API/UI 의존성을 들이지 않고 양쪽 체크인에 재사용할 수 있다.
3. **P1 대화 연결:** ConversationMachine은 LlmConversationResponse와 verse 상태에 의존한다.
   파일을 통째로 복사하거나 `verse`를 일괄 치환하지 않는다. 기존 wire 값은 Christian adapter에 보존한다.
4. **P1 저장 연결:** Christian `soul_bible.mind_cards.v1`은 기존 JSON과 문구를 유지해야 한다.
   Buddhist `onaria.buddhist.test_only.cards.v1` ID 목록은 이후 새 schema가 생겨도 조용히 버리지 않는다.
   새 저장 모델은 버전과 migration 테스트를 갖추되 운영 DB migration은 하지 않는다.
5. **P1 회귀 자동화:** 별도 Buddhist 앱은 현재 root `flutter test`로 검사되지 않는다.
   Web workflow도 `backend/**`만 경로 필터에 포함해 공유 Mock 패키지만 바뀌면 실행되지 않을 수 있다.
   공통 모델 연결과 함께 Buddhist 테스트 및 공유 패키지 영향 검증을 CI에 추가할 계획이다.
6. **P2 이후:** 음성/공유/알림은 재사용 가능한 동작과 종교적 문구를 구분해서 작은 단위로 이관한다.

양쪽 앱 전체를 한 프로젝트의 dependency로 연결하지 않는다. root ONARIA dependency를 Buddhist에
추가하면 Bible asset 및 Christian 기능이 함께 딸려올 수 있다. 공유는 작은 `packages/` 단위로 한다.

## 목표 모듈 목록 — 아직 구현하지 않은 계획

| 소유 위치 | 포함할 내용 | 포함하지 않을 내용 |
|---|---|---|
| `packages/onaria_core` | Safety, 감정·강도 입력 모델, 종교 중립 상태, 저장 계약 | 경전 본문, Bible 타입, 종교 문구, 운영 endpoint |
| Christian의 기존 모듈/adapter | 기존 wire 이름·저장 키·BibleProvider·기도 문구 | Buddhist Mock이나 테마 |
| `packages/onaria_buddhist_pack` | Mock Provider, 출처/권리 검증, 성찰 문구 | 외부 경전 수집, 차단 자료, 사용자 계정 |
| `apps/buddhist` | Buddhist UI 구성, 로컬 저장 adapter, Android 진입점 | Christian 데이터 읽기, 운영 API 자동 연결 |
| backend 개발 composition root | dev pipeline, 모델/Provider 인터페이스, 테스트 주입 | production app 자동 교체, 운영 DB/인증 설정 수정 |

자료 없음은 “인용 없음”으로 처리한다. 성찰/실천/카드 흐름을 유지하기 위해 근거 없는 인용을 만들지 않는다.
추후 인용 없는 카드를 지원할 때도 인용 필드는 비우고 일반 성찰 문구와 출처를 구분해야 한다.

## 순차 실행 계획

| 작업 | 범위 | 완료 기준 |
|---|---|---|
| **2-A: 다음 구현** | 공통 감정 모델·체크인 입력 계약, Buddhist의 감정/강도/직접 입력 | 아래 수용 기준 통과 |
| 2-B | 중립 대화 상태·ReligionProfile 경계 | 교차 Pack 요청 거부, Safety 선행, Christian wire 유지 |
| 3-A | Buddhist 단계별 로컬 대화·성찰·작은 실천 | 턴/동의/자료 없음/오류 복구 테스트, 모델 호출 0 |
| 3-B | 상세 카드·저장/복원·목록 | Provider 원본 인용만 사용, 기존 ID 목록 호환, 저장 실패 처리 |
| 4 | 맥락/감정 기반 대화 고도화 | 우선 가짜 클라이언트로 계약 검증. 실제 모델 연결은 dev 설정·비용 범위 확정 후 |
| 5 | 계정·기록 요구사항 | 기존 social ‘준비 중’ 및 동기화 부재를 반영, 별도 dev identity/storage 설계 |
| 6 | 성장 → 공유 → 음성 → 알림 | 기능별 이관 후 Christian 회귀; 게임은 별도 범위 결정 |
| 7 | 개발 Admin 확장 | 인증/CSRF/마스킹/종교별 접근 제어, 차단 자료 활성화 불가 |
| 8 | 통합·실기기 검증 | 양쪽 빌드 자산 격리, 각 기능 회귀, 승인된 Buddhist Release 키로 설치 |

### 다음 구현 2-A의 수용 기준

- 기존 16개 EmotionType의 이름·라벨·자연어 표현·fromWire 동작을 보존한다.
- 감정 모델은 공통 패키지로 분리하되 기존 Christian import 경로는 호환 export로 유지한다.
- 체크인 입력 계약은 감정, 강도 1~10, 선택적 직접 입력을 명시한다. UI 외 경로에서도 범위를 검증한다.
- Buddhist에서 선택한 감정/강도/직접 입력이 같은 체크인 객체로 대화에 전달된다.
- 직접 입력의 위기 신호는 대화 진입 전 감지하고 Mock 검색/카드로 이어지지 않는다.
- 공유 모듈에서 Bible 자료형·root ONARIA asset·운영 API를 import하지 않는다.
- 이번 작은 작업에서는 AI 연결, 계정, 상세 카드 migration, 기존 Christian 문구/화면 변경을 하지 않는다.
- 기존 Christian 감정·대화·체크인·Safety 회귀와 Buddhist 입력/위기 테스트를 함께 실행한다.
- 변경 영향에 맞게 Flutter analyze, Android 빌드, 공통 Dart 변경의 iOS simulator compile을 확인한다.
- CI에 Buddhist 앱 테스트를 명시하고 공유 패키지 변경이 검사에서 빠지지 않게 한다.

## 현재 검증과 CI 제한

이번 점검에서 실제 재실행:

- backend Buddhist Pack/Christian 종교/자료 회귀: **32/32 PASS**.
- Christian conversation_machine/safety_parity/onaria_storage_compatibility: **9/9 PASS**.
- Buddhist Flutter 테스트: **6/6 PASS**.
- 문서만 변경하므로 새 APK/실기기 설치/전체 빌드는 실행하지 않는다.

읽기 전용 CI 조회:

- [Web/Admin 실패](https://github.com/Naharuya/onaria/actions/runs/36366827838):
  `0536d99...`의 `npm run test:web` 단계 실패. 세부 테스트 원인은 이번 단계에서 확정하지 않았다.
- [App QA 성공](https://github.com/Naharuya/onaria/actions/runs/36366827827): 위와 같은 원격 SHA 기준이며 현재 dirty 작업의 검증 결과가 아니다.
- [macmini workflow 실패](https://github.com/Naharuya/onaria/actions/runs/36366824432): job 목록 없음. 원인 미확정.
- Cafe24 packaging 최근 2건은 SKIPPED. 어떤 실패/생략도 PASS로 처리하지 않는다.
- 현재 로컬 미커밋 변경의 정확한 SHA CI는 **NOT RUN**이다. workflow를 실행하거나 배포하지 않았다.

## 종료 및 다음 작업

1단계 산출물은 기능 비교표, 공유 모듈 경계, 2-A의 수용 기준이다.
실행 코드와 설치된 앱은 이번 점검에서 변경하지 않았다. 다음 작업은 **2-A 공통 체크인 모델 연결**이다.
실제 불교 경전 수집/투입은 계속 금지하며, 별도 라이선스 검증 및 2차 지시 이후에만 다룬다.
