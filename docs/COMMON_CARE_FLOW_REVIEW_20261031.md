# 네 앱 공통 동선 구현·검증 보고서

확인 시각: 2026-10-31T06:28:01.450985+00:00. 대상은 현재 ONARIA, NAREUM, maeon, SORUA다. 이전 philosophy 시안은 현재 철학 앱으로 비교하지 않는다.

감정 확인 → 마음 대화 → 전통별 콘텐츠 → 작은 실천 → 카드·기록의 순서와 위치 표시를 공통화했다.
정상 종료 후 이어가기, 콘텐츠 없이 실천, 미니게임 없이 저장 후 기록 화면 이동을 지원한다.
외부 AI/운영 로그인/DB 수집을 이번 작업으로 새로 켜지 않았다. 네 앱은 각자 소유한 코드·콘텐츠·계정·서버·키·저장 정책을 유지한다.

| 앱 | 전체 Flutter 통과 / 건너뜀 | Backend 통과 | 분석 | Web TEST | Android TEST 컴파일 |
| --- | --- | --- | --- | --- | --- |
| ONARIA | 213 / skip 1 | 529 | PASS | PASS | PASS |
| NAREUM | 295 / skip 1 | 553 | PASS | PASS | PASS |
| maeon | 258 / skip 0 | 433 | PASS | PASS | PASS |
| SORUA | 228 / skip 1 | 575 | PASS | PASS | PASS |

ONARIA의 대화 한도 경계 테스트 3개는 전체 실행 뒤 추가한 별도 검사다. 전체 Flutter 수와 중복 합산하지 않는다.
정확한 종료 코드·원본 로그 SHA256·소스 파일 SHA256·소스 버전과 HEAD는 각 앱 docs/CARE_FLOW_IMPLEMENTATION_20261031.json에 있다.
건너뜀은 통과 수에 포함하지 않는다. 정보 수준 분석 지적과 기존 plugin의 Wasm/Gradle/SwiftPM 경고는 기능 통과와 별도로 남긴다.
Web 검증 대상은 JavaScript다. WebAssembly를 검증했다고 표시하지 않는다.

## 실제 수정

- 네 앱이 동일한 CareStep 순서와 앱 소유 CareFlow 계약 사본을 사용한다. 현재 위치 표시는 단계 이동 버튼이 아니며 동의·안전 검사를 우회하지 않는다.
- 기독교·불교·SORUA의 처리 중/위기/화면 종료 뒤 전환을 제한한다. 정상 대화 종료 후에는 사용자가 콘텐츠 선택 또는 작은 실천을 고를 수 있다.
- 불교·SORUA는 최대 대화 횟수에 도달한 안전한 응답을 콘텐츠 선택으로 이어가도록 정리했다. 명시적 대화 종료와 위기 처리는 그대로 우선한다.
- 기독교·불교·가톨릭에 카드 저장 후 기록 화면으로 직접 가는 선택지를 추가했다. SORUA의 기존 직접 이동 경로를 같은 검사로 검증했다. 기존 미니게임/공유 경로는 보존했다.
- 기독교 소개 웹과 서비스 설명도 다섯 단계로 맞추고, 리디자인에서 빠진 접근성/SEO 항목을 복구했다. 과거의 출시 전 문구를 테스트의 현재 사실로 강제하지 않는다.
- 불교 화면 테스트는 스크롤 후 한 프레임을 그린 뒤 누르도록 보정했다. 애니메이션 미니게임에 무한 대기하는 검사 방식은 사용하지 않는다.
- 가톨릭 분석 지침은 실제 존재하는 lib/test 경로를 사용한다. 없는 example 경로를 만들거나 검사 성공으로 가장하지 않는다.

## 처음 실패한 검사와 수정/재확인

- 기독교 Backend: 초기 소개 웹 2항목 불일치 수정. 서버 기동의 짧은 시간 제한은 낮은 동시성으로 재검사했다.
- 불교 Flutter: 초기 화면 탭 3항목과 대화 한도 1항목을 수정하고 관련 테스트 및 전체 검사를 다시 실행했다.
- 불교 Backend: 격리 서버 기동은 단독 실행에서 PASS했다. 전체 검사는 파일 동시성1로 재확인하며 시간 제한 자체를 늘리지 않았다.
- 가톨릭 분석: 존재하지 않는 example 경로를 뺀 정확한 명령으로 다시 실행했다.
- SORUA: 다섯 번째 응답을 종료로 강제하던 기존 테스트 기대값을 콘텐츠 선택으로 갱신하고 명시 종료/위기 검사를 유지한 뒤 전체 재검증했다.
- 초기 실패 로그와 중단된 불교 보조 테스트는 최종 통과로 덮지 않는다. 최종 결과는 JSON의 verification, 초기 결과는 initialValidation으로 구분한다.

## 앱별 유지한 차이와 한계

가톨릭은 외부 대화 AI 비활성·로컬 성찰을 유지한다. 카드는 이번 실행 세션 메모리에만 남으며 앱 재시작 복원은 이번 작업에 포함하지 않는다.
불교의 공개 승인 인용이 없는 상태에서 인용을 생성하거나 테스트 원문을 Release에 넣지 않는다.
SORUA는 현재 실제 앱을 기준으로 하며 로컬 성찰/회원·동의 후 전용 AI라는 경계를 유지한다.
콘텐츠 권리·교리/편집 검수·스토어 고지·운영 계정 연결을 공통 UI 통과만으로 완료 처리하지 않는다.
TEST 빌드는 컴파일 검증용이다. 설치본/스토어 버전과 소스 기본 빌드 번호가 다를 수 있으므로 기기 버전·서명 대조 전에 설치하지 않는다.

## 작업 범위

BUILD는 로컬 컴파일, TEST는 자동 검사다. 실제 기기 설치·운영 배포·실제 제공자 호출·스토어 업로드·새 심사 제출·정식 공개·CI 실행·commit/push는 수행하지 않았다.
검증 대상은 기존 미커밋 변경을 포함한 현재 작업 파일이며 HEAD 하나로 동일한 산출물을 재현한다고 표시하지 않는다. 기존 미커밋 변경을 보존했다. SORUA는 최초 커밋/원격이 없는 상태를 임의로 변경하지 않았다.
현재 기준은 각 앱 docs/COMMON_CARE_FLOW.md 및 AGENTS.md이며 과거 비교 보고서는 당시 증거로 보존한다.

## 이 저장소 완료 보고

~~~yaml
PROJECT: "onaria"
CURRENT COMMIT: "40cd65851553238c426b32f5af2639e76f24f64b"
ISSUE FOUND: "Legacy comparison target and inconsistent end/record navigation."
PRIORITY: "P1 core user flow"
ROOT CAUSE: "No shared journey contract; inherited completion rules differed."
IMPLEMENTED: "Five stages, safe continuation, direct records path, current-app documentation."
CHANGED FILES: ["lib/care_flow.dart", "test/common_care_flow_test.dart", "test/common_care_flow_navigation_test.dart", "lib/features/check_in_page.dart", "lib/features/conversation_page.dart", "test/common_care_flow_budget_test.dart", "backend/public/website/redesign-20261030/index.html", "backend/src/website_content.js", "backend/test/onaria_web.test.js", "AGENTS.md", "README.md", "docs/COMMON_CARE_FLOW.md", "docs/COMMON_CARE_FLOW_REVIEW_20261031.md", "docs/CARE_FLOW_IMPLEMENTATION_20261031.json", "ONARIA_STATUS.md"]
TEST: {"analyze": {"status": "PASS"}, "flutter": {"status": "PASS", "passed": 213, "skipped": 1}, "backend": {"status": "PASS", "tests": 529, "pass": 529, "fail": 0, "skipped": 0}, "additionalBoundaryTests": {"passed": 3, "status": "PASS"}}
BUILD: {"web": 0, "androidDebug": 0, "iosSimulator": 0}
DEVICE: "NOT RUN - no installation requested"
API: "NOT RUN - no live provider or production activation"
CI: "NOT RUN - local verification only"
COMMIT: "NOT RUN - not requested; existing mixed changes preserved"
PUSH: "NOT RUN - not requested"
REMAINING RISKS: "Local code/builds do not establish device, production or store parity; Catholic records remain session-only."
NEXT ACTION: "Use this contract for subsequent changes; verify target device version/signature before any later authorized install."
~~~
