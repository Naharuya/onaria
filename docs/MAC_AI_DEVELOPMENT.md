# ONARIA Mac AI 개발 실행

맥의 Ollama `qwen3:8b`를 ONARIA 마음대화에 연결한다. 앱 API 계약은 유지하며,
운영 API와 실기기 Release 설치 설정은 변경하지 않는다.

## 실행

Ollama가 `127.0.0.1:11434`에서 실행 중이고 `qwen3:8b`가 설치되어 있어야 한다.
저장소 루트에서 다음 명령을 실행한다.

```sh
node backend/scripts/run_mac_ai.mjs
flutter devices
flutter run -d <IOS_SIMULATOR_ID> --dart-define=ONARIA_API_BASE_URL=http://127.0.0.1:8791
```

실제 휴대폰에는 위 Debug 명령을 사용하지 않는다. iOS 시뮬레이터의 loopback은
맥 개발 서버에 연결된다. Android 에뮬레이터를 사용하는 경우 기존 Debug
override 정책에 따라 `http://10.0.2.2:8791`을 사용한다.

개발 서버는 `127.0.0.1:8791`에만 바인딩하며 기존 8787 서버를 중단하지 않는다.
`.env`나 저장된 OpenAI 자격증명을 읽지 않는다. 회원 데이터는 Git에서 제외된
`backend/data/mac-ai/members.sqlite`에 별도로 저장한다. 생성 API에는 로컬 개발
설정상 사용자 인증이 없으므로 터널이나 외부 포트로 공개하지 않는다.

## 동작과 경계

- `ONARIA_AI_MODE=ollama`가 명시된 서버만 로컬 모델을 사용한다.
- 일반 마음대화는 구조화된 한국어 공감·후속 질문·답변 예시를 한 번에 생성한다.
- 위기 입력과 세션 위기 상태는 모델 생성·호출·종교 검색보다 먼저 고정 응답으로 처리한다.
- 종교 질문은 기존 검색·인용·종교 무결성 검증을 사용한다. 이 경로는 production
  corpus 검증을 적용하므로 개발용 sample 자료를 근거로 쓰지 않는다. 승인된 자료가
  없으면 근거 부족을 안내하며 경전·교리 생성으로 보완하지 않는다.
- 로컬 요청도 출력 스키마와 내용 무결성 검증을 거친다.
- 추론은 서비스 인스턴스당 하나만 실행한다. 중복 요청·18초 초과·잘못된 응답은
  기존 고정 응답으로 돌아간다. OpenAI 자동 전환은 구현하지 않았다.
- Ollama 통신은 loopback HTTP만 허용하고 redirect와 cloud 모델 이름을 거부한다.
  로컬 모델을 운영자가 cloud 모델 별칭으로 교체해서는 안 된다.
- 로그는 provider, 호출 수, 토큰 수, 지연, 실패 분류만 남기며 대화 원문을 기록하지 않는다.
  로컬 추론의 `estimatedCostUsd=0`은 외부 API 요금이며 장비·전기 비용을 포함하지 않는다.
  로컬 추론은 기존 유료 API ledger 집계에 포함하지 않는다.

## 검증

```sh
cd backend
node --test test/ollama.test.js
npm test
```

고정 안전 응답의 모델 호출 0, 정상 입력의 실제 모델 경로, 시간 초과·동시 요청,
잘못된 출력, 승인 근거 없는 종교 생성 차단, loopback 제한을 검사한다.

현재 연결 범위는 맥 개발 서버와 시뮬레이터다. 앱마켓 Release는 계속 공식
`https://api.onaria.ai.kr`에 연결된다. 운영 도입에는 별도의 보안 연결, 운영 서버
가용성·동시 접속·품질 평가 및 승인된 CI artifact 배포가 필요하다.
