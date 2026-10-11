# ONARIA 소셜 identity Build 20 검증

## 사전점검
- PROJECT: ONARIA, HEAD `1aef3815c8e25022a948c4307e1c755e5cc8507b`, branch `codex/apple-android-20261006`. 기존 dirty 작업 트리 보존. 후보는 별도 임시 사본에서 검증. 병합·리베이스·커밋·푸시 미실행.
- 지시서의 과거 DB 상태와 달리 실제 사전점검은 회원 1명, identity 2개(Google/Kakao), 전화번호 nullable·UNIQUE 없음. 동일 회원/provider UNIQUE만 누락. S22/A33의 시작 설치본도 이미 빌드 20. 이전 빌드 18/19 보고를 현재 검증으로 재사용하지 않음.

## 구현 및 격리 검증
- provider/session 로그인과 provider/signup 신규 가입 분리 유지. 미등록 404 `PROVIDER_IDENTITY_NOT_FOUND`, 이미 가입된 identity signup 409 유지. 프로필 자동 병합 없음.
- attachIdentity를 IMMEDIATE transaction으로 보호. 동일 회원/provider의 다른 identity는 `PROVIDER_ALREADY_LINKED` 409, 타 회원 소유는 `IDENTITY_EXISTS` 409. 동일 identity 반복은 idempotent. 새 세션 발급 성공 뒤 기존 세션 철회.
- fresh DB 양쪽 UNIQUE 선언. 기존 DB 변경은 명시적 `migrate_social_identities.js --check/--apply`, 별도 백업 필수. 중복 ownership 발견 시 적용 차단. 회원·identity 전체 내부 digest/시퀀스 보존, 반복 no-op. 서버 시작 시 자동 migration 없음.
- Flutter 미등록 분기는 명시적 404 code만 인정. 다른 404를 신규 회원으로 오인하지 않음. 계정 연결 응답의 구조화 오류 code 보존. 외부 SDK 없이 credential loader/HTTP mock으로 화면·pending 보존 검증.
- Backend 기준 483 PASS, identity 보완 후 전체488 PASS/0 FAIL, 로컬 서버 시작 회귀 추가 후 최종489 PASS/0 FAIL. 추가·관련 9 PASS. 삭제 명부·복원·원장 보호 기존 회귀 포함.
- Flutter 변경 전 170 PASS/1 SKIPPED, 최종 전체 174 PASS/1 SKIPPED. 새 identity UI 4 PASS(기존 세션이 있어도 명시적 선택, 실패 credential 보존/재시도, 관련 없는404 차단,320px/2배율 포함). 정적 분석 오류 0/경고 0/info 15. 최종 전체 재실행 PASS.

## Production 적용
- PASS: 승인된 최소 인증 패키지 4파일(app/store/migration module/CLI)만 적용. 다른 웹·AI·서버 설정은 교체하지 않음.
- 최신 복구 사본 `/opt/onaria-backups/social-identity-build20-20261010-212344`: 회원·세션·비용 DB와 기존 소스 보존. 실제 SSH 주소/키 경로는 공개 문서에 기록하지 않음.
- 서비스 stop → 명시적 migration → 데이터/ownership/sequence 불변 확인 → start. phone nullable/비고유 유지, UNIQUE(provider,provider_user_id) 및 UNIQUE(member_id,provider) PASS. 회원 1→1, identity 2→2. integrity ok/FK 오류 0. 회원 삭제·임의 병합·identity 수동 변경 없음.
- PASS: 로컬 8787 및 공개 HTTPS health status ok/version 1.0.0/build 20.
- 과거 후보의 삭제 명부 전체 운영 연결은 이번 최소 배포에 포함하지 않음. 설정 일치·격리 테스트와 운영 삭제/복원 Gate는 별도이며 완료로 간주하지 않음.

## Build·실기기
- 최종 APK/AAB 생성·기존 인증서 SHA-256 일치 PASS. com.onaria.app/1.0.0+20/targetSdk36 유지. S22/A33 기존 Release 설치 엔진의 인증서·package·version 검사 후 adb install -r 및 실행 PASS. iOS signed Release 생성 및 codesign --verify --deep --strict PASS, 기존 Team BJL8U6B46S/1.0.0+20. 스토어 업로드 없음.
- S22/A33 Google 교차 로그인: PASS(두 기기 로그인 성공 사용자 응답, 서버 회원1/identity2 불변). 기타 provider 교차 인증: NOT RUN. Google 로그인 후 신규 회원 오염 없음 확인. 나머지 provider는 각 단계 aggregate 확인 예정.
- iPhone: 실제 설치 조회는1.0.0+19. 후보1.0.0+20은 빌드/엄격 서명 PASS이나 설치·인증 회귀 NOT RUN, Android 교차 인증 이후 진행.

## 남은 Gate
- BLOCKED: Apple 콘솔 Return URL 전체 문자열 미확인(끝부분 추측 금지). 실제 Apple 인증·연결은 별도 실제 증거 필요.
- BLOCKED: 백업 외부 사본/최장 복원 가능 시점 및 미정 보유기간. 30일/37일 적용 없음.
- NOT RUN: 실제 회원탈퇴(비가역적 회원 변경은 disposable 테스트 계정과 별도 승인 전 실행하지 않음), 스토어 제출, 병합·리베이스·커밋·푸시.
- 최종 판정: BLOCKED — 실기기 교차 인증·iPhone·최종 회귀 대기.

## 최종 후속 소스/패치 검증
- 기존 세션이 있어도 미등록 identity는 chooseAction으로 이동. 자동 attach 분기 제거. PHONE_EXISTS를 계정 연결로 유도하던 잔여 임시 안내 제거. 프로필과 소유권 분리 유지.
- 초기 패치와 `ONARIA_SOCIAL_IDENTITY_BUILD20_EXPLICIT_CHOICE_2026-10-10.patch`를 별도 검증 사본에서 순서 적용 PASS. 역적용으로 초기 작업 트리 해시를 복원·대조 PASS, 정방향 적용 결과 최종 후보와 byte-identical PASS. 원본에는 충돌 검사 후 필요한 로컬 변경만 반영.
- fetch origin/main 완료: HEAD 대비 ahead5/behind4. 병합/리베이스 없음.
- 후보 HTTP 진단은 고정 operation/status 또는 timeout/network/tls/transport만 허용. credential/header/body 원문 출력 없음. iOS 임시 진단은 최대64줄. 과거 iPhone 인증 실패 원인은 미확정 유지.
- Apple 콘솔 전체 Return URL 확인 요청 중. 외부 계정 인증은 사용자 직접 조작 외 자동 수행 없음.

## 현재 단계 완료/차단 판정
| 단계 | 판정 | 근거 |
|---|---|---|
| 사전점검/기존 작업 보존 | PASS | 프로젝트/HEAD/branch/origin 재확인, reset/clean/stash/병합 없음, 기존 변경 및 초기 hash 대조 |
| canonical identity/API/DB guard | PASS | 전화번호 자동 병합 없음, authenticated dedicated link, IMMEDIATE transaction/두 UNIQUE, 충돌409/중복안전/세션 철회 격리 검증 |
| Production migration/최소 인증 배포 | PASS | 최신 백업,1회원/2identity 및 모든 행·소유권·sequence 보존, integrity ok/FK0, 두 제약 확인 |
| 최종 백엔드 회귀 | PASS |489/0실패. 시작 smoke가 deletionManifest 변수명 오타를 찾아 로컬 수정. 운영 server.js 변경 없음 |
| Flutter/분석 | PASS |174 PASS/1 SKIPPED, 오류0/경고0/info15. 미등록 상태·가입 선택·연결/재시도·소형 화면/글자2배·양OS 버튼 순서 |
| APK/AAB/iOS signed Release | PASS | 기존 인증서/Team,package,bundle,버전20,targetSdk36 유지. 해시 manifest 기록 |
| S22/A33 데이터 유지 업데이트 | PASS | 최종 소스+보호 define 파일로 재빌드, Release 엔진 install-r/실행 확인. uninstall/clear 없음 |
| S22/A33 Google 로그인 | PASS | 두 기기 성공 사용자 확인, 회원1/identity2 불변. 최종 갱신 이후 양 기기 account GET200 고정 진단 확인 |
| Naver 교차 연결/직접로그인 | BLOCKED | 사용자 직접 인증 조작 결과 대기. 현재 DB Naver identity없음. 신규 가입 금지 안내 |
| Kakao 교차 로그인/연결 | NOT RUN | 이미 canonical 회원에 Kakao1개 연결됨. 같은 계정은 직접 로그인, 다른 Kakao계정 자동 대체는 금지. 격리 동일provider충돌 PASS와 실제검증 구분 |
| Apple Android/전체callback | BLOCKED | 콘솔 Return URL 전체 대조 응답 및 사용자 실제 인증 필요. challenge/state/nonce 기존 설계 보존. 실검증 PASS아님 |
| iPhone20 설치/4-provider 회귀 | NOT RUN | 실제 설치19 확인. Android 완료 후 서명20 업데이트/사용자 인증 진행 |
| 실제 회원탈퇴 | BLOCKED | 비가역적 조작은 disposable 계정과 별도 승인 전 수행하지 않음. 격리 삭제/manifest 회귀 PASS와 운영 구분 |
| CI/스토어/Git 통합 | NOT RUN | 후보의 확정 commit/CI 없음. 병합/리베이스/커밋/푸시/스토어 업로드 없음 |

- 최종 health 재조회: HTTP200/status ok/version1.0.0/build20. 회원1/identity2(Google1/Kakao1), integrityok/FK0. 세션 없는 account GET401.
- 비밀값: 수정 소스·패치·문서에 기존 보호 Kakao/서명 password 값이 포함되지 않음 대조 PASS. git diff --check PASS. 키/비밀번호/token/provider payload 출력 없음.
- 로컬 시작 수정 별도 패치 `ONARIA_BUILD20_LOCAL_STARTUP_2026-10-10.patch`. 전체 삭제 명부의 운영 연결은 이번 최소 인증 배포와 별도 Gate 유지.
- 자동 수행 가능한 개발/격리 회귀/빌드/승인된 비파괴 migration·기기 업데이트를 수행했다. 다음 진행은 사용자 직접 공급자 인증 응답을 기다리는 지점이다.
- 현재 판정 **BLOCKED**. 해결 완료 선언 금지. 30일/37일 정책·회원 수동 변경·실제 삭제/철회·스토어 제출·병합/커밋/푸시 없음.

## 사용자 응답 후속: Apple 전체callback / Naver SDK 실패
- Apple 콘솔 전체 Return URL: **PASS**. 사용자가 전체 `https://api.onaria.ai.kr/v1/auth/apple/android/callback` 정확한 일치 확인. 운영 `ONARIA_APPLE_REDIRECT_URI` 또는 코드 기본값과 읽기 전용 대조도 true. 앞선 전체주소 BLOCKED 기록은 이 항목에 한해 해소. 실제 Apple 인증/계정연결은 여전히 NOT RUN, 설정 일치만으로 인증 PASS 선언하지 않음.
- A33 Naver 교차 인증: **FAIL**. 사용자 보고는 네이버 로그인·동의 완료 후 ONARIA에서 SDK 로그인 실패. 고정 HTTP 진단상 account GET200 및 logout DELETE204 이후 provider/session POST 없음. 서버 계정연결 요청 전 SDK 결과 실패로 구분. HTTP401이나 DB migration 원인으로 단정하지 않음.
- 실패 후 운영 회원1/identity2(Google1/Kakao1), integrityok 유지. 네이버 identity 생성 없음.
- 원인: **미확정**. 기존 일반 오류 문구는 native 오류 code를 숨겨 구체적인 provider 원인을 판별할 수 없었음. SDK raw error/payload/전체로그는 출력·저장하지 않음.
- APK 설정: 원본/후보 보호 네이버 설정 일치, 실제 APK resource client ID/client secret 값이 보호 파일과 일치 확인(값 출력 없음). 잘못된 key, callback, 취소 등을 근거 없이 원인으로 확정하지 않음.
- 진단 구현: 허용 목록의 네이버 오류 code/프로필 결과 처리 단계만 노출. 알 수 없는 native 문자열은 unknown. SDK loggedOut는 사용자 취소로 단정하지 않고 logged_out로 분류. ONARIA_AUTH_DIAGNOSTICS opt-in일 때 고정 `ONARIA_NAVER_SDK stage=login code=...`만 출력. 본문/credential/private native 메시지는 전달하지 않음. 실제 오류를 성공으로 우회하거나 브라우저 인증으로 대체하지 않음.
- 관련 SDK/새로운 credential 요청/identity UI 회귀 **9 PASS**, analyze 오류0/경고0/info15. 추가 테스트2개는 안전한 분류·private payload 비노출을 검증. 전체 Flutter 재검증 진행 중(직전174 PASS/1SKIPPED와 구분).
- A33 진단 후속 Build20: 기존 서명/버전/데이터 유지 install-r 및 실행 PASS. S22/기존 AAB/iOS 산출물은 앞선 identity 최종 후보 단계이며 새 SDK 오류 표시를 적용한 것으로 간주하지 않음. 원인 확인·최소 수정 후 필요 산출물/기기 일치 검증 예정.
- 사용자 조작: A33에서 한 번 재시도 후 고정 SDK code만 보고 요청. 기존회원 연결 선택 전 SDK 단계 결과부터 확인. 새 계정 생성/회원삭제/외부철회/설정변경 없음.
- 최종판정 **BLOCKED** 유지. Apple callback 설정 Gate만 PASS, Naver 실검증 FAIL 및 원인 확인 대기.

네이버 진단 후속 최종 회귀: Flutter176 PASS/1 SKIPPED, 관련9 PASS, analyze오류0/경고0/info15. A33 고정 SDK code를 확인하는 사용자 재시도 대기. 실제 원인·수정완료·네이버실검증 PASS는 선언하지 않음. 운영 추가 변경/회원삭제/외부철회/커밋/푸시 없음.

## A33 네이버 실기기 화면 증거: SDK logged_out
- 사용자 제공 화면에서 `네이버 SDK가 로그인 완료 상태를 반환하지 않았어요. (SDK: logged_out)` 확인. 네이버 로그인·동의 완료 후 실패라는 사용자 보고와 함께 기록. **Naver 실검증 FAIL / 원인 미확정 / 완료 판정 BLOCKED**.
- 설치된 SDK Android 소스의 반환 경로를 확인했다. 로그인 실패 callback에서 `user_cancel` 또는 설명에 cancel이 포함된 경우와, 로그인 성공 callback 이후 access token이 없는 경우가 모두 동일한 loggedOut 상태로 반환된다. 따라서 이 화면만으로 사용자 취소·토큰 누락 중 어느 경로인지 구분할 수 없다. Dart 결과 파서는 대소문자를 정규화하므로 상태 문자열 대소문자 불일치를 이번 원인으로 볼 근거는 없다.
- 다음 진단 조건: 위 두 native 반환 경로를 구분하는 고정 단계 코드만 수집해야 한다. SDK 원문 오류·토큰·계정 정보 출력, 캐시 토큰으로 로그인 성공 간주, loggedOut 무시, 외부 철회 방식의 초기화는 금지한다. 원인 입증 전 SDK/운영 설정을 임의 변경하지 않는다.
- 이번 후속은 읽기 전용 SDK 코드 검토와 문서 기록만 수행. 기기 재설치·운영 변경·회원 데이터 변경·회원삭제·외부 철회·병합·커밋·푸시 없음. 이전 회귀 결과와 이번 신규 실기기 성공을 혼동하지 않는다.
