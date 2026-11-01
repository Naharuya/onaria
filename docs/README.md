# 개발 문서 안내

현재 상태와 과거 보고서가 섞이지 않도록 문서의 역할을 나눴습니다. 동일한 테스트 결과를 여러 문서에 다시 적지 않고 해당 버전의 검증 기록을 연결합니다.

## 먼저 볼 문서

| 목적 | 기준 문서 |
| --- | --- |
| 프로젝트 소개·실행 | [README](../README.md) |
| 2026-09-11 기능별 검증 스냅샷 | [ONARIA_STATUS](../ONARIA_STATUS.md) |
| Build24 소스 통합 기록 | [ONARIA_MAIN_INTEGRATION](releases/ONARIA_MAIN_INTEGRATION_2026-10-11.md) |
| 다음 작업의 순서·보류한 작업 | [ONARIA_ROADMAP](../ONARIA_ROADMAP.md) |
| 완료를 판단하는 기준 | [ONARIA_GATES](../ONARIA_GATES.md) |
| 0.4.1 수정·검증·배포 기록 | [릴리즈 점검](releases/APP_REVIEW_2026-09-11.md) |

## 확정된 제품·데이터 목적

- [선택적 답변 평가와 반복 문구 개선 정책](FEEDBACK_ADAPTIVE_PHRASE_POLICY_2026-10-24.md) — 2026-10-24 사용자 결정. 반복 답변 문구의 능동적 추가 저장을 지원하는 목적과 실제 구현 확인 범위를 구분합니다.

## 개발 지침

- [프로젝트 폴더 구조·정리 기준](guides/PROJECT_STRUCTURE.md)
- [기술 구성·배포](guides/TECH_STACK_AND_DEPLOYMENT.md)
- [테스트 안내](guides/TESTING_GUIDE.md)
- [사용 흐름과 코드 위치](guides/PROCESS_CODE_MAP.md)
- [위기 대응 분류](guides/SAFETY_CATEGORIES.md)
- [앱 초대 링크 설계](APP_INVITATION_LINKS.md) — 공개 활성화는 로드맵의 보류 상태를 따릅니다.
- [십자가 게임 연결 점검](CROSS_LIGHT_FLOW_REVIEW.md)

## 과거 개발 보고서

아래 문서의 수치와 완료 상태는 당시 결과입니다. 현재 버전의 결과로 사용하지 않습니다. 서로 다른 시점의 수정 근거가 있어 내용을 삭제하거나 하나의 완료 판정으로 합치지 않았습니다.

| 주제 | 기록 |
| --- | --- |
| 빌드·런타임 | [빌드 복구](archive/BUILD_REPAIR_REPORT.md), [런타임 복구](archive/APP_RUNTIME_REPAIR_REPORT.md) |
| 참여·성장 기능 | [참여 연결](archive/ENGAGEMENT_INTEGRATION_REPORT.md), [성장 흐름](archive/GROWTH_FLOW_REPORT.md), [AI 외 개발](archive/NON_AI_DEVELOPMENT_REPORT.md) |
| 십자가 게임 | [구현](archive/CROSS_LIGHT_GAME_REPORT.md), [베타](archive/CROSS_GAME_BETA_REPORT.md) |
| 인증·AI 비용 | [인증](archive/IDENTITY_INTEGRATION_REPORT.md), [비용 제한](archive/AI_COST_GATE_REPORT.md), [비용 영속성](archive/AI_COST_GATE_PERSISTENCE_REPORT.md) |
| 안전·개인정보 | [안전 검증](archive/SAFETY_VERIFICATION_REPORT.md), [보안·개인정보 점검](archive/SECURITY_PRIVACY_REVIEW.md) |

## 백엔드 및 별도 앱

- [멀티 에이전트 개요](../backend/MULTI_AGENT_INTEGRATION.md)
- 단계별 고유 구현 이력: [1](../backend/PHASE_1_INTEGRATION.md) · [2](../backend/PHASE_2_INTEGRATION.md) · [3](../backend/PHASE_3_SPECIALIZATION.md) · [4](../backend/PHASE_4_RAG.md) · [5](../backend/PHASE_5_VECTOR_RAG.md) · [6](../backend/PHASE_6_PRODUCTION_CORPUS.md) · [7](../backend/PHASE_7_EXPERT_CORPUS.md) · [8](../backend/PHASE_8_PILOT_RELEASE.md) · [9](../backend/PHASE_9_CHRISTIANITY_A_TRACK.md)
- 관리자: [API 설정](../backend/ADMIN_API_SETTINGS.md), [관리자 PWA](../backend/ADMIN_PWA.md)
- RAMI는 독립 GitHub 저장소 `Naharuya/RAMI`에서 관리하며 ONARIA 저장소에는 소스를 중복 보관하지 않습니다.

## 문서 갱신 원칙

STATUS는 현재 2026-09-11 스냅샷이며 최신 전체 현황으로 갱신되지 않았습니다. 소스 버전은 `pubspec.yaml`, 이후 변경·검증은 해당 `releases/` 기록과 실제 대상 버전의 실행 증거를 함께 확인합니다. 실행 순서는 ROADMAP, 완료 기준은 GATES에서 관리합니다. 버전별 테스트·설치 증거는 `releases/`, 과거 작업 이력은 `archive/`, 반복해서 참고하는 지침은 `guides/`에 둡니다. 루트에 같은 역할의 새 보고서를 계속 추가하지 않습니다.

이번 정리에서는 루트 Markdown 21개 중 17개를 이동했습니다(과거 보고서 12개, 지침 4개, 릴리즈 기록 1개). 앱 소스·환경 설정·서명키·DB·APK는 정리 대상으로 변경하거나 삭제하지 않았습니다.
