# Buddhist 5단계 — 개발용 계정·기록 요구사항

상태: 요구사항 및 설계 완료. 아래의 개발용 identity/repository는 아직 구현하거나 활성화하지 않았다. 기본 앱은 로그인 없는 오프라인 TEST_DATA_ONLY 앱으로 유지한다. 이 문서는 실제 인증·동기화·계정 데이터 이관 승인이 아니다.

## 1. 현재 코드에서 확인한 사실

| 영역 | 현재 상태 | 근거 |
|---|---|---|
| 앱 시작 | Provider와 SharedPreferences를 읽고 세션 생성, 계정 조회 없음 | [main.dart](../apps/buddhist/lib/main.dart) |
| 카드 기록 | v1은 ID 목록, v2는 version/cards와 scriptureId/savedAt; owner 없음 | [mind_card_store.dart](../apps/buddhist/lib/mind_card_store.dart) |
| 대화 맥락 | 최근 두 답변을 메모리에만 유지, 새 체크인/위기 때 비움 | [session.dart](../apps/buddhist/lib/session.dart) |
| 출처 | 저장된 본문이 아니라 Provider에서 다시 확인 | [session.dart](../apps/buddhist/lib/session.dart) |
| Android | com.onaria.buddhist 별도 앱, main manifest에 INTERNET 없음, allowBackup=false | [AndroidManifest.xml](../apps/buddhist/android/app/src/main/AndroidManifest.xml) |
| Christian 소셜 UI | 네이버·카카오·Google 버튼에 ‘준비 중’ 표시 | [signup_page.dart](../lib/features/signup_page.dart) |

Christian 소셜 UI 상태는 소스만 읽어 확인했다. 운영 사용자·DB·토큰·계정 설정은 조회하지 않았다. 기존 Christian 인증을 그대로 복제할 수 있다고 가정하지 않는다.

## 2. 이번 설계 결정

1. 로그인 없이 체크인·Mock 대화·동의·마음카드 저장을 사용하는 guest 흐름이 기본이다.
2. 개발 identity는 합성 fixture 두 개(`dev-user-a`, `dev-user-b`)로만 검증한다. 실제 이메일·이름·전화번호·소셜 ID·비밀번호를 받지 않는다.
3. identity provider와 기록 repository를 분리한다. fake identity를 실제 인증 성공으로 표시하거나 운영 endpoint에 사용할 수 없도록 한다.
4. 기존 guest 카드의 v1/v2 원본은 보존한다. fake 계정으로 자동 이동·복사·귀속시키지 않는다.
5. 종교 profile은 앱 구성에서 Buddhist로 고정한다. 계정·요청 본문의 religion/owner 값으로 바꾸지 않는다.
6. 기기 내 테스트 계정 간 분리는 기능 검증용 논리적 분리다. 실제 사용자 인증이나 암호화 저장의 보안성을 갖췄다고 주장하지 않는다.
7. 실제 로그인·서버 저장·동기화는 후속 범위다. 이번 단계에서 INTERNET 권한, OAuth 설정, production DB migration, 기존 서명키/package 변경을 하지 않는다.

## 3. 기록별 보관·노출 요구사항

| 데이터 | 현재/제안 보관 위치 | 개발 identity 전환 시 | 원격 전송 |
|---|---|---|---|
| 감정·강도·직접 입력 | 현재 세션 메모리 | 화면 및 맥락을 비움 | 없음 |
| 최근 대화 답변 | 메모리 최대 두 개 | 비움; 새 계정 요청에 포함 금지 | 없음 |
| 위기 수준 | 실행 중 Safety 상태 | 유지; 전환/로그아웃으로 위험도 해제 금지 | 없음 |
| 기존 guest 카드 | 기존 v1/v2 로컬 키 | guest에서만 표시, 원본 유지 | 없음 |
| 합성 계정 카드 | 후속 fake repository의 계정별 메모리 partition | 현재 합성 owner 것만 표시 | 없음 |
| 경전 본문·출처·권리 | Provider 원본 | 항상 재검증, 차단 시 숨김 | 없음 |
| 개발 진단 | 오류 코드/건수만 | 사용자 입력·카드 본문·식별자 로그 금지 | 없음 |

합성 계정 repository의 첫 구현은 메모리 기반으로 제한한다. 앱 재시작 시 합성 계정 기록이 사라지는 것이 기대 동작이며, guest의 기존 로컬 카드는 유지한다. 실제 데이터 보존/삭제 정책을 확정하지 않은 상태에서 영구 계정 저장을 도입하지 않는다.

## 4. 후속 구현용 인터페이스 계약 (제안)

- `DevIdentityProvider.current`: guest 또는 사전에 등록한 fixture principal만 반환한다. 입력 문자열을 임의 principal로 승인하지 않는다.
- `RecordScope`: app=Buddhist, environment=TEST_DATA_ONLY, principal, generation으로 구성한다. 서비스가 identity provider에서 생성하며 UI 입력으로 만들지 않는다.
- `MindCardRepository.list(scope)`: 검증된 scope의 참조만 반환한다. 다른 owner/profile/environment면 명시적 실패이며 guest 전체 목록으로 fallback하지 않는다.
- `MindCardRepository.save(scope, reference)`: reference는 scriptureId와 savedAt만 허용한다. 임의 본문·출처·번역자·owner 필드는 거부한다. 서비스에서 Provider 검증을 선행한다.
- `generation`: 전환 때 증가하는 세션 번호다. 이전 scope로 시작한 늦은 읽기/쓰기 완료가 현재 계정 화면이나 목록을 변경하지 못하게 한다.
- 기존 guest 저장 adapter는 현재 v1/v2 계약을 유지한다. 합성 fixture repository와 저장 키를 공유하지 않는다.

API endpoint·OAuth provider·사용자 DB 테이블은 이번 계약에 정의하지 않는다. 개발용 fixture 식별자는 인증 토큰이 아니며 서버에 보내지 않는다.

## 5. 전환과 실패 처리

| 상황 | 기대 동작 |
|---|---|
| 앱 시작 | guest로 시작, 기존 guest 카드 복원, 로그인 요구 없음 |
| guest → fixture A | Safety 먼저 평가, pending 입력 제거, 대화/카드 미리보기 비움, A의 테스트 목록만 표시 |
| A → B | generation 증가, A의 진행 중 응답은 B에 반영하지 않음; 계정별 목록 분리 |
| A → guest | A 자료가 섞이지 않고 기존 guest 목록 복원; 데이터 삭제 없음 |
| 위기 상태에서 전환 | 계정 전환으로 지원 화면/차단을 해제하지 않음; 모델·Psychology·Religion 호출 0 |
| 존재하지 않는 principal | 실패, 현재 principal/목록 유지; 자동 계정 생성 없음 |
| 읽기 실패 | 원시 오류나 이전 계정 목록을 노출하지 않음; 해당 scope에서 재시도 |
| 저장 실패/중복 클릭 | 성공 표시 없음, 기존 데이터 유지, 중복/갱신 유실 방지 |
| 전환 중 이미 시작한 쓰기 | 원래 scope에만 귀속; 현재 scope로 재시도하거나 복사하지 않음 |
| 알 수 없는 카드/차단 권리 | 인용과 카드에서 제외, 대체 경전 생성 없음 |
| 손상된 guest 기록 | 현재 정책 유지: 원본 보호 및 저장 차단, 자동 초기화 없음 |

guest→실제 계정 이전은 구현하지 않는다. 나중에 도입한다면 사용자가 검토한 기록 범위, 명시적 동의, 중복/실패 복구 정책을 먼저 확정해야 한다. 현 단계의 ‘다음 단계’ 지시는 production 데이터 이관 허가로 해석하지 않는다.

## 6. 수용 테스트 — 향후 코드 구현 때 실행

이 목록은 테스트 계획이며 이번 턴에 PASS로 주장하지 않는다.

| ID | 시나리오 | 합격 기준 |
|---|---|---|
| ID-01 | guest 기본 실행 | 인증 클라이언트 생성/네트워크 0, 기존 Mock 흐름 사용 가능 |
| ID-02 | v1/v2 guest 복원 | ID·시각·기존 bytes 유지, fixture 계정에 자동 복사 없음 |
| ID-03 | A 저장 → B 조회 → A 조회 | B에 A 기록 0개, A 복귀 시 A 기록 유지 |
| ID-04 | owner/profile/environment 위조 | 읽기/쓰기 거부, Provider 및 외부 호출 0 |
| ID-05 | A 응답 대기 중 B 전환 | A 결과가 B UI/목록에 적용되지 않음 |
| ID-06 | 계정 전환 전후 위기 corpus | 고정 local crisis 응답 및 sticky risk 유지, 후속 모델/종교 호출 0 |
| ID-07 | 위기 입력을 보내지 않고 전환 | 선택 동작보다 Safety 선행, 자료 노출 없음 |
| ID-08 | 저장 실패·동시 저장·재시도 | 기존 목록 보존, 실패 UI, 다른 scope로 쓰기 금지 |
| ID-09 | 차단/위조 Provider 인용 | 본문·경전명·장절·번역자·출처 생성/노출 없음 |
| ID-10 | A→B 및 새 체크인 | 이전 입력/선택/상세 카드/맥락이 다음 요청에 포함되지 않음 |
| ID-11 | 앱 재시작 | guest 영구 기록 유지, fake 메모리 기록 소멸; 복구된 계정처럼 표시하지 않음 |
| ID-12 | Christian 회귀·양쪽 자산 검사 | Christian API/wire 보존, 서로의 콘텐츠 혼입 시 FAIL |

실제 계정 UI/서버 연동 전에 공급자 선택, 별도 dev 환경, 세션 만료·취소·계정 복구, 접근 제어, 필요한 보관 범위와 사용자 동의를 검토한다. 지금 비밀값이나 개인 정보를 요구하지 않는다.

## 7. 구현 순서와 종료 지점

이번 5단계 결과물은 이 설계와 기존 코드 근거 검토다. 앱의 동작·저장 형식·버전을 변경하지 않는다.

후속 구현 후보를 5-A로 한정한다: 합성 identity provider와 메모리 repository의 순수 계약, scope/generation 검사, ID-01~ID-12 중 적용 가능한 자동 테스트. 기본 앱에 계정 선택 UI를 노출하거나 실제 로그인처럼 보이게 하지 않는다. 이것이 준비된 뒤 성장/공유/음성/알림 이관 범위를 정한다.

실제 경전과 한국어 번역문은 별도 라이선스 검증과 2차 지시 전까지 투입하지 않는다. BLOCKED_EXTERNAL_REVIEW 자료는 어떤 계정에서도 사용 불가다. production 변경, 앱스토어 제출, push는 수행하지 않는다.

## 8. 이번 턴의 검증

문서 링크·근거 파일 존재·계약 일관성·diff·비밀정보 패턴을 검사한다. 코드 변경이 없으므로 Flutter/backend 테스트, Android/iOS 빌드, 실기기 설치, API 호출은 NOT RUN이다. 이전 턴의 PASS 결과를 이번 실행 결과로 표시하지 않는다. 새 커밋 CI는 push 보류로 NOT RUN이다.
