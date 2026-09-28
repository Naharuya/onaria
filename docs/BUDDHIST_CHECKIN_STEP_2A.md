# 2-A — 공통 체크인 모델과 Buddhist 연결

2026-09-28, `feature/onaria-buddhist`.

## 변경

- 기존 16개 `EmotionType`을 `packages/onaria_core/lib/src/emotion.dart`로 내용 변경 없이 이동했다.
  Christian의 기존 import 경로는 공개 export로 유지한다. enum 이름·라벨·자연어 표현·fromWire
  기본값·기존 API wire 값은 유지한다.
- `CheckInInput`은 감정, 강도 1~10, 선택적 직접 입력을 갖는 불변 객체다.
  UI 밖에서도 범위를 검증하며 공백 입력은 null, 직접 입력은 최대 2,000 code unit으로 제한한다.
- Buddhist 화면에서 16개 감정, 강도 슬라이더, 직접 입력을 하나의 객체로 세션에 전달한다.
  전달된 선택과 강도를 결과에 표시한다. 체크인 본문을 영구 저장하거나 전송하지 않는다.
- `beginCheckIn`이 직접 입력의 Safety를 먼저 검사한다. 위기이면 대화 시작을 거부하고
  고정 로컬 응답을 보여 준다. 이후 메시지와 새로운 체크인으로 위험을 낮출 수 없다.
- Provider spy로 위기 corpus 전체에서 검색 0회를 검증했다. 기존 코드에는 모델/API client가 없다.
- Buddhist 버전은 0.1.1+2로 올렸다. 이번 단계에서는 기기에 설치하지 않는다.

## 범위 유지

실제 경전·번역문, AI 연결, 계정, 카드 schema migration, Christian 문구 변경은 없다.
Safety 원본 규칙과 Bible dataset, production API/DB, signing key는 변경하지 않는다.

## 로컬 검증

| 검증 | 결과 |
|---|---|
| 변경 전 Christian 체크인·대화·Safety | 16 PASS |
| 변경 전 Buddhist | 6 PASS |
| 변경 후 Christian 감정·체크인·대화·통계·API·Safety | 21 PASS |
| Buddhist 전체 | 11 PASS — 위기 검색 0회, 360px/글자 2배, 입력 전달, 카드 흐름 포함 |
| backend Buddhist/Christian 관련 | 32 PASS |
| Release 설치 안전장치 | 21 PASS, Windows 전용 1 SKIP |
| Buddhist Web E2E | 4 PASS |
| Buddhist Android Release | PASS — 전용 키, 0.1.1+2 |
| Christian Android Debug | PASS — 설치하지 않음 |
| Christian iOS simulator | PASS — 설치하지 않음 |

초기 UI 테스트는 스크롤 직후 레이아웃 반영 전에 버튼을 눌러 실패했다.
스크롤 완료 후 프레임을 기다리도록 고쳐 재실행했으며, 실패를 PASS로 간주하지 않았다.
기존 tracked 수정 14개가 이번 단계에서 덮어써지지 않았음을 파일 해시로 확인했다.

## CI와 커밋 범위

기존 Android QA workflow에 별도 Buddhist 테스트·분석·unsigned Release compile·자산 검사를 추가했다.
Web workflow에는 공유 Buddhist 패키지 경로와 별도 Mock E2E 실행을 추가했다.
CI는 서명 비밀값을 받지 않으며 Buddhist APK를 배포하거나 기기에 설치하지 않는다.

아직 커밋되지 않았던 Buddhist 앱·공통 Safety·Mock Pack·전용 설치기는 이번 체크인 기능의
필수 기반이다. 이 관련 파일을 함께 체크포인트로 기록하되 기존 Ollama 코드, roadmap,
사용자 테스트 수정, iOS registrant 수정은 포함하지 않는다.
root pubspec.lock은 공통 Core 의존성 변경만 선택하고 다른 기존 변경은 작업 트리에 보존한다.
선택된 커밋 대상만 임시 snapshot으로 구성하여 backend 전체 408 PASS, Christian 관련 21 PASS,
Buddhist 11 PASS를 다시 확인했다. 작업 트리의 Ollama 관련 6개 테스트는 이 snapshot에 포함되지 않는다.
워크플로 YAML 구문 및 staged 72개 파일의 secret/서명 파일 혼입 검사를 통과했다.
정확한 커밋 SHA의 원격 CI 결과는 실행 후 최종 보고에서 구분한다.

다음 작업은 2-B의 종교 중립 대화 상태·ReligionProfile 경계다.
