# Buddhist 3-B — 상세 마음카드·저장/복원·목록

## 결과

저장 목록에서 카드를 선택하면 Provider 원본 본문·출처·이용 조건·TEST_DATA_ONLY 상태와 저장 시각을 확인할 수 있다. 비어 있는 목록, 상세에서 목록으로 돌아가기, 저장 실패 후 재시도, 읽을 수 없는 기록 안내를 추가했다. 상세 진입 시 스크롤을 초기화하여 큰 글씨에서도 제목부터 확인할 수 있다.

## 저장 계약

- 신규 저장 키: `onaria.buddhist.test_only.cards.v2`.
- 단일 JSON 값에 version=2와 cards 배열을 저장한다. 각 행은 scriptureId와 UTC savedAt만 가진다. 경전 본문, 출처, 대화 원문, 체크인 감정/강도는 저장하지 않는다.
- 기존 `onaria.buddhist.test_only.cards.v1` ID 목록을 읽으며 자동 삭제/변경하지 않는다. 저장 시각은 추측하지 않고 null 및 ‘이전 버전 기록’으로 표시한다.
- 새 카드를 저장할 때만 v2 값을 기록한다. 이전 참조도 보존한다. 중복 ID 저장은 원래 시각과 기록을 유지한다.
- 목록과 상세는 Provider에서 ID를 다시 확인하고 원본 메타데이터 검증을 통과한 TEST_DATA_ONLY 자료만 표시한다. 외부·다른 종교·알 수 없는 ID는 표시하지 않는다.
- 손상된 JSON, 지원하지 않는 버전, 임의 본문 필드, 잘못된 날짜 등은 읽기를 차단한다. 원래 저장값을 보존하고 새 저장을 막아 조용히 덮어쓰지 않는다. 기록 삭제/복구 도구는 이번 범위에 없다.
- 저장 성공 후에만 메모리 목록을 갱신한다. false/예외 시 캐시를 다시 읽고 원래 목록을 유지하며 재시도 가능하다. 동시 저장은 거부하여 갱신 유실을 막는다.
- 위기 감지 이후 새 저장 및 상세 접근은 차단하고 목록을 숨긴다. 위기 감지 전에 이미 플랫폼으로 전달된 비동기 쓰기는 취소/삭제하지 않지만 완료 후 UI에 노출하지 않는다.

## 안전 경계

Buddhist 로컬 앱만 변경했다. Core, Christian 실행 코드·데이터·Bible dataset, production DB, nginx/DNS/SSL, 서명키는 변경하지 않았다. 실제 경전 수집·저장과 외부 API/모델 호출은 없다. BLOCKED_EXTERNAL_REVIEW 자료는 계속 사용 불가다.

## 검증

| 검사 | 결과 |
|---|---|
| 변경 전 Christian 관련 | 18 PASS |
| 변경 전 Buddhist 전체 | 26 PASS |
| 변경 후 Christian 전체 Flutter | 125 PASS, 1 SKIP (기존 사용자 미커밋 테스트 포함 작업 트리 기준) |
| 변경 후 Buddhist 전체 Flutter | 34 PASS |
| Buddhist analyze | 지적 사항 없음 |
| 격리 backend 계약/인용/Safety/HTTP | 10 PASS |
| 기존 Buddhist Web E2E | 4 PASS (신규 Android 카드 UI는 Flutter 위젯 테스트로 검증) |
| Buddhist Android Release | 0.1.3+4 빌드 PASS |
| APK 인증서·package·권한·자산 | 기존 전용 pin 일치, com.onaria.buddhist, non-debuggable, INTERNET 없음, Mock만 포함 |
| Christian Android/iOS 재빌드 | NOT RUN — 이번 변경은 별도 Buddhist 앱에 한정, 공유/Christian 코드 변경 없음 |
| 실기기 설치·실제 디스크 재시작 복원 | NOT RUN — 자동 테스트는 mock preferences 기반, 기기 검증은 별도 |
| 운영 API·배포·앱스토어 | NOT RUN — 범위 밖 |
| push·현재 커밋 CI | NOT RUN — 사용자가 나중에 일괄 push하도록 명시 |

E2E는 LISTEN 검사 후 localhost 동적 빈 포트를 사용했다. 새 테스트의 중복 `_` 매개변수 컴파일 오류를 수정했고, 2개 UI 테스트의 스크롤 완료 대기를 보완했다. 최종 전체 테스트와 분석은 재실행하여 통과했다.

## 다음 범위

3-B에서 종료한다. 다음 후보는 4단계 대화 맥락/감정 계약 고도화이며, 우선 가짜 클라이언트로 검증한다. 실제 모델 연결, 실제 경전·번역문 투입, 원격 push는 실행하지 않았다. 실제 경전은 별도 라이선스 검증 및 2차 지시를 기다린다.
