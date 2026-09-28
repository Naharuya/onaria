# Buddhist 2-B — 공통 대화 상태와 종교 경계

## 범위

`ConversationState`, `ConversationPhase`, `ReligionProfile`을 순수 Dart Core에 추가하고 BuddhistSession에 연결했다. profile은 앱 생성 시 Buddhist로 고정되며 사용자 메시지로 변경되지 않는다. 체크인, 턴 수, 위기 수준은 불변 상태로 관리한다. 현재는 기존 단일 응답 Mock 흐름을 유지하며, 단계별 질문·동의·실천 대화는 3-A 작업이다.

안전 검사를 먼저 실행한다. 위기이면 고정 로컬 응답을 표시하고 검색하지 않는다. 정상 입력이면서 다른 profile을 요청하면 PACK_MISMATCH로 거부하고 이전 인용·카드·응답을 비운다. 위기 수준은 후속 메시지나 새 체크인으로 낮아지지 않는다.

Christian용 순수 변환 어댑터는 중립 sourceOffer/sourceReflection과 기존 verse_offer/verse_reflection을 대응시킨다. 기존 Christian 실행 경로·API 직렬화·상태 기계는 교체하지 않았다. 모든 legacy 단계의 왕복 변환과 wire 이름을 테스트한다. 전체 Christian 상태 기계 이전은 이번 범위가 아니다.

## 데이터·운영 경계

실제 경전 수집·다운로드·저장 없음. TEST_DATA_ONLY Mock provider만 사용한다. production 서비스, DB, 사용자 데이터, Bible dataset, nginx/DNS/SSL, 서명키는 변경하지 않았다. 새 상태를 디스크에 저장하지 않는다. 인터넷·모델 클라이언트·심리 Agent를 추가하지 않았다.

## 검증

- 변경 전: Christian 관련 7개, Buddhist 11개 PASS.
- 변경 후: Buddhist 14개 PASS, analyze clean.
- Christian wire 및 Core 경계 포함 관련 테스트 10개 PASS.
- 격리 backend 10개 PASS. 위조 인용·교차 Pack·위기 corpus 포함.
- Buddhist Web E2E 4개 PASS. LISTEN 확인 후 127.0.0.1 동적 포트 사용.
- Buddhist Release APK 컴파일 PASS. 기존 전용 인증서 pin 일치, com.onaria.buddhist, non-debuggable, INTERNET 없음, Mock asset 존재 및 Bible asset 없음 확인.
- 실기기 설치·운영 API 호출·배포는 실행하지 않았다. 원격 push는 이전 자동 승인 심사 차단 상태이며 신규 CI 증거 없음.

최종 회귀 검사 결과는 아래에 기록한다.

- Christian 전체 Flutter: 125 PASS, 1 SKIP (현재 작업 트리 기준, 기존 사용자 미커밋 테스트 포함).
- Safety/계약/공통 상태 집중 회귀: 18 PASS.
- root analyze: 기존 example/main.dart avoid_print info 4건, 새 오류/경고 없음.
- Christian Android/iOS 재빌드: NOT RUN — 기존 실행 코드 변경 없이 변환 어댑터만 추가, 이번 모바일 컴파일은 Buddhist Release 대상으로 실행.
