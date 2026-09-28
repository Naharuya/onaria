# Buddhist 5-A~8단계 검증 보고서

2026-09-28. 범위: TEST_DATA_ONLY 오프라인 MVP. 5-A~7 구현 및 8단계 자동 검증/Release 설치 완료. **8단계 실기기 화면 검증은 잠금 해제 대기 상태이며 완료로 판정하지 않는다.**

## 구현

- 5-A: guest 저장소를 유지하고 합성 fixture A/B 기록을 메모리로 분리했다. issuer/scope/generation 검증으로 다른 계정·만료 scope 접근 및 늦은 저장 성공 표시를 차단한다. 실제 로그인·계정 UI·동기화는 없다.
- 6: Provider로 재검증한 저장 카드 기준 최근 7일 건수, 합성 카드 공유 미리보기와 Android 공유 선택 화면, 오프라인 한국어 TTS, 사용자가 선택하는 1회 쉼 알림을 구현했다. 대화·감정·계정 식별자를 공유하지 않는다. 앱이 다른 사람에게 자동 전송하지 않는다.
- 6 Safety: 위기 시 카드·인용을 먼저 제거하고 고정 안내를 표시한다. 음성과 예약 알림을 취소하며 진행 중 권한 요청도 이후 예약하지 못하도록 막는다. 기기 listener 예외가 Safety 처리를 중단하지 않는다.
- 7: localhost 개발 Admin에 현재 브라우저 세션의 요청 건수와 제한 상태만 표시한다. 입력 본문·인용·식별자는 진단에 포함하지 않는다. 읽기 전용, 세션 분리, Origin/CSRF, no-store, 종교 고정 검증을 유지한다. import/외부 승인/publish/reset은 비활성이다.
- 8: 자동 회귀, 양쪽 앱 자산 분리, 빌드와 서명 검증 및 Buddhist Release 설치를 수행했다.

## 이번 실행 결과

| 항목 | 결과 / 범위 |
|---|---|
| Buddhist Flutter | 50 PASS; identity, 저장, Safety, 기기 채널 실패/취소, 360px 글자 배율 1/2 흐름 포함 |
| Buddhist analyze | 문제 없음 |
| Christian Flutter | 작업 트리 전체 125 PASS / 기존 1 SKIP; 각 기능 후 집중 회귀 10 PASS |
| backend | 작업 트리 415 PASS; 별도 staged snapshot 409 PASS (기존 사용자 Ollama 변경 제외) |
| Buddhist Web E2E | 5 PASS; loopback LISTEN 검사 후 빈 localhost 포트 사용 |
| Release 설치 도구 | 21 PASS / Windows 전용 1 SKIP |
| Buddhist Android | 0.2.0+6 Release 빌드 PASS; 기존 전용 인증서·package·버전·offline 자산 검증 PASS |
| Christian Android/iOS | Android debug 및 iOS simulator compile PASS; analyze 기존 avoid_print 정보 4개 |
| 자산 격리 | Buddhist APK에 mock만, Christian APK에 Bible만 포함되는지 검사 PASS |
| 실기기 설치 | 기존 설치와 인증서 비교 후 adb install -r 성공, com.onaria.buddhist 실행 명령 성공 |
| 실기기 화면·음성·알림 | NOT RUN: 휴대폰 잠금 화면으로 UI 검사 불가, 사용자에게 잠금 해제 요청 중 |
| 운영 API/DB/배포 | NOT RUN: 사용자 금지 범위 |
| 정확한 신규 SHA CI | NOT RUN: 사용자 요청으로 push 보류 |

Mac에 pwsh가 없어 PowerShell 설치 wrapper가 호출하는 동일한 `scripts/android-release.mjs --buddhist` 엔진을 사용했다. 키 변경, uninstall, 데이터 초기화, Christian 앱 설치는 수행하지 않았다. 마지막 Safety 수정까지 포함하여 Release를 다시 설치했다.

Widget 테스트 초기 실행 중 Provider 파일 읽기가 fake async에 갇히는 현상을 수정해 setUp에서 로드하도록 했다. 중단된 실행을 성공으로 집계하지 않고 전체를 다시 실행했다.

## 한계와 남은 확인

- 성장 화면은 저장 카드 건수이며 심리 평가·치료 효과·수행 점수가 아니다.
- 음성은 기기에 설치된 오프라인 한국어 TTS 출력만 지원한다. 음성 입력/온라인 음성 엔진은 범위 밖이며, 음성이 없으면 사용할 수 없다고 표시한다. 실제 청취 확인은 아직 하지 못했다.
- 알림은 1분 테스트 또는 24시간 뒤 1회 inexact 예약이다. OS 절전 정책으로 지연될 수 있고 재부팅 뒤 다시 설정해야 한다. 실제 도착·권한 거절/허용은 휴대폰에서 확인이 남았다.
- 공유 선택 화면 호출 성공은 메시지 전송 성공을 의미하지 않는다. 실제 수신자에게 보내는 작업은 수행하지 않았다.
- 합성 identity는 보안 인증이 아니며 fixture 기록은 재시작 때 사라진다. 기존 guest 저장을 계정으로 이관하지 않는다.
- 개발 Admin은 localhost 세션 진단 도구이며 운영 관리자 인증의 대체물이 아니다.

실기기 잠금 해제 후 기존 카드 복원 → 공유 미리보기/선택 화면 취소 → TTS 재생·중단 → 알림 허용/거절·취소·도착 → 위기 차단을 확인하면 8단계의 남은 실기기 검증을 닫을 수 있다. 미확인 항목은 PASS로 승격하지 않는다.

## 종료 경계

실제 경전·번역문을 수집하거나 저장하지 않았다. 외부 권리 미확인 자료는 BLOCKED_EXTERNAL_REVIEW이며 응답/검색/마음카드에 사용할 수 없다. 실제 AI·로그인·production DB migration·배포·앱스토어 제출·push는 수행하지 않았다. 기존 사용자 변경은 이번 커밋 대상에서 제외한다. 현재 범위에서 멈추며 실제 경전 투입은 별도 라이선스 검증과 2차 지시를 기다린다.
