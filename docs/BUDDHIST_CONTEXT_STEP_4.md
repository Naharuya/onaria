# Buddhist 4단계 — 로컬 맥락·감정 응답 계약

## 구현 범위

Buddhist guided reply에 주입 가능한 동기식 LocalConversationClient와 기본 Mock 구현을 연결했다. 실제 모델, HTTP, credentials, 서버 변경은 없다. 이번 계약은 로컬 가짜 클라이언트 검증용이며 네트워크 지연/취소/타임아웃을 처리하는 원격 API 계약은 아니다.

요청은 고정 Buddhist profile, 체크인 감정·강도, 다음 허용 단계, 현재 입력 및 최근 두 개의 승인된 답변으로 구성한다. 이전 답변 목록은 수정 불가능한 복사본이다. 대화 맥락은 메모리에만 보관하고 새 체크인/마무리 후 재시작/위기 감지 때 비운다. 저장 카드 형식과 개인정보 저장 범위는 바꾸지 않았다.

기본 Mock은 강도 8 이상이면 천천히 답할 수 있는 필요 질문을, 그 외에는 선택한 감정을 반영한 질문을 고른다. 최근 입력의 ‘쉬/쉼’ 키워드가 있으면 쉼 관련 자료 보기 안내를 선택한다. 단순한 규칙이며 사용자의 감정이나 의도를 AI가 분석했다고 주장하지 않는다.

응답은 profile·phase·template 세 필드만 허용한다. 단계별 허용 template은 앱 내 고정 문구로 변환한다. 임의 본문·경전명·출처·추가 필드, 다른 종교/단계, 알 수 없는 template은 거부한다. 오류와 유효하지 않은 응답은 기존 고정 안내로 복구하고 정상 흐름을 이어 간다. 원시 예외는 표시하지 않는다.

## Safety·종교 경계

클라이언트 factory는 Safety, profile, 길이 및 단계 검사 이후에만 호출한다. 초기 위기 입력은 가짜 클라이언트 생성·호출도 0이다. 실제 모델 호출과 실제 AI 클라이언트 생성은 항상 0이다. 클라이언트 실행 중 재진입으로 위기가 감지되면 반환된 응답이 위기 상태를 덮어쓰지 못한다.

클라이언트는 경전 검색/인용/동의 상태를 변경할 수 없다. 사용자가 동의한 뒤 기존 BuddhistScriptureProvider의 TEST_DATA_ONLY 자료만 조회한다. 자료 없음/위조 인용/차단 자료 규칙은 유지한다. 실제 경전·번역문 수집과 투입은 하지 않았다.

## 검증 및 제한

- 변경 전 Christian 관련 10 PASS, Buddhist 전체 34 PASS.
- 변경 후 Buddhist 전체 40 PASS. 맥락·강도 전달, immutable history, Safety 전체 corpus의 factory/call 차단, 잘못된 입력/profile, 위조 응답, 예외 복구, 재진입 위기 보존 포함.
- 기존 격리 backend 10 PASS, Web E2E 4 PASS. Web 테스트는 기존 Web 흐름 회귀이며 신규 Android 계약은 Flutter 테스트로 검증한다.
- E2E 실행 전 LISTEN 포트를 확인하고 127.0.0.1의 동적 빈 포트 사용.
- 신규 lint 1건은 중괄호를 추가하여 수정 후 분석/계약 테스트를 다시 실행했다.
- 실기기 설치: NOT RUN. Christian Android/iOS 재빌드: NOT RUN (공유/Christian 코드 변경 없음).
- 운영 API, 배포, 앱스토어, 실제 경전 수집: NOT RUN (범위 밖).
- push 및 새 커밋 CI: NOT RUN (사용자가 나중에 일괄 push하도록 요청).

실제 원격 AI 연결은 개발 설정·비용·비동기 Safety 계약을 별도로 검증하기 전까지 진행하지 않는다. 다음 계획 후보는 5단계 계정·기록 요구사항의 개발 전용 설계다. 기존 Christian 사용자 데이터에는 접근하지 않는다.

최종 확인: Christian 전체 Flutter 125 PASS/1 SKIP (기존 미커밋 테스트가 포함된 작업 트리 기준), Buddhist analyze 지적 사항 없음, 최종 계약 집중 테스트 6 PASS. Buddhist Release 0.1.4+5 빌드 PASS. 기존 전용 인증서 pin·com.onaria.buddhist·non-debuggable·INTERNET 없음·Mock-only 자산 확인 PASS.
