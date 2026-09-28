# Buddhist 3-A — 로컬 단계별 대화·회고·실천

## 구현

Buddhist Android UI를 단일 검색 응답에서 다음 고정 로컬 흐름으로 연결했다.

1. 감정·강도·직접 입력 체크인
2. 상황 이야기
3. 필요한 것 알아차리기
4. 합성 테스트 자료를 볼지 명시적으로 선택
5. 자료가 있으면 회고, 거절하거나 자료가 없으면 실천 선택으로 이동
6. 작은 실천 또는 선택하지 않기 → 감정·강도·선택을 표시하는 마무리
7. 기존 Provider 원본 마음카드 저장 또는 새 체크인

Core에 phase를 지정하는 입력 처리와 Safety를 해제하지 않는 화면 단계 전환을 추가했다. 기존 호출의 기본값과 Christian wire/상태 기계는 유지했다. Buddhist의 단계 전환은 세션이 검증하며 동의 전 검색, 잘못된 단계 이동, 임의 실천 값, 빈 입력 및 2,000자 초과 입력을 거부한다. 이전 단일 응답 메서드도 guided 세션 안에서는 단계별 응답으로 연결되어 동의를 우회하지 않는다.

## Safety·인용·개인정보

- 6개 단계에 공통 Safety corpus 적용. 위기이면 고정 로컬 응답, 인용/카드 제거, 이후 정상 메시지나 새 체크인으로 위험도 해제 불가.
- 보내기뿐 아니라 자료 동의/거절, 실천, 카드 생성/저장, 탭 이동 전에 입력창의 미전송 위기 문구도 검사한다.
- 자료 조회 실패 시 내부 오류는 표시하지 않고 동의 단계에서 재시도/자료 없이 진행 가능.
- 검색 결과가 없으면 인용을 만들지 않는다. 조회된 자료도 Provider의 원본 검증을 거친다.
- 문장들은 일반적인 고정 UI 안내이며 경전/교리로 표시하지 않는다. 자료는 TEST_DATA_ONLY 합성 fixture만 사용한다.
- 대화 답변 원문은 저장하지 않는다. 체크인은 메모리, 기존 카드 저장은 Provider ID만 사용한다. DB migration 없음.
- 모델/외부 API 클라이언트 추가 및 실제 경전 수집 없음. Christian 운영 서비스·데이터·서명키 변경 없음.

## 검증 결과

| 항목 | 결과 |
|---|---|
| 변경 전 Christian 관련 검사 | 18 PASS |
| 변경 전 Buddhist 전체 | 14 PASS |
| 변경 후 Christian 전체 Flutter | 125 PASS, 1 SKIP (현재 작업 트리의 기존 미커밋 테스트 포함) |
| 변경 후 Buddhist 전체 Flutter | 26 PASS |
| Buddhist analyze | 오류·경고·info 없음 |
| Christian analyze lib test example --no-fatal-infos | 기존 example avoid_print info 4건, 오류/경고 없음 |
| 격리 backend 계약·Safety·인용·HTTP | 10 PASS |
| 기존 격리 Buddhist Web E2E | 4 PASS (Android 신규 흐름은 Flutter 위젯 테스트로 검증) |
| Buddhist Android Release | 0.1.2+3 빌드 PASS |
| Christian Android Debug | 빌드 PASS, 설치하지 않음 |
| Christian iOS simulator | 컴파일 PASS, 실기기 실행 아님 |
| 빌드 자산 분리 | Buddhist에 Bible/Christian 자산 없음, Christian에 Buddhist/Mock 자산 없음 |
| Buddhist 서명/패키지/권한 | 기존 전용 인증서 pin 일치, com.onaria.buddhist, non-debuggable, INTERNET 없음 |
| 기기 설치/운영 API/배포 | NOT RUN — 이번 단계 범위 밖 |
| 새 커밋 CI | NOT RUN — 이전 원격 push 차단 유지 |

E2E는 LISTEN 포트를 먼저 확인한 뒤 127.0.0.1의 동적 빈 포트로 실행했다.

검증 중 신규 테스트를 root에서 실행하여 package resolution 오류가 한 번 발생했으며 앱 폴더에서 재실행했다. 추가한 카드 버튼 테스트 2개는 화면 밖 ListView 항목이 아직 렌더링되지 않아 실패했으며 scrollUntilVisible로 수정 후 전체 26개가 통과했다. 중간 실패를 최종 PASS 결과로 대체하지 않고 이력을 남긴다.

## 제한과 다음 작업

고정 로컬 질문이며 답변 의미를 분석하는 AI 상담은 아니다. 실제 경전 데이터 및 번역문 투입은 별도 라이선스 검증과 2차 지시까지 금지한다. unreviewed 자료는 BLOCKED_EXTERNAL_REVIEW로 사용 불가 상태를 유지한다. 앱 재실행 후 대화 재개/실천 기록 저장은 이번 범위가 아니다.

다음 후보는 3-B 상세 마음카드·저장/복원·목록이다. 이번 작업은 3-A에서 종료한다. 원격 push, production 배포, 앱스토어 제출은 수행하지 않았다.
