# Buddhist ONARIA 디자인·맥미니 AI 개발 연결

2026-09-28. 사용자 요청: ONARIA 디자인을 기준으로 오방색 적용, 사용성/기능/Safety/회귀 재검증, 맥미니 AI 연결, 실제 경전 검토.

## 구현 범위

- 기존 `lib/app/app_theme.dart`, `space_scaffold.dart`, `features/check_in_page.dart`를 읽어 같은 어두운 배경·별빛·중앙 심볼·체크인 안내·감정 카드 구성과 20px 모서리/54px 주요 버튼을 Buddhist에 적용했다. 기존 Christian 파일은 변경하지 않았다.
- 청·적·황·백·흑 계열만 사용하고 텍스트·선택 체크로 상태를 구분한다. Christian 종교 심볼/본문/기능을 복사하지 않았다. Buddhist 탐색과 TEST_DATA_ONLY 표시는 유지한다.
- 초기 소개는 체크인에서만 표시하고 대화 중에는 입력·응답에 집중한다. 최대 본문 폭 620, 큰 글꼴에서는 감정 카드 2열이다. 유한한 체크인 폼을 하나의 스크롤에 유지해 입력 위젯이 화면 밖에서 사라지지 않게 했다.
- 별도 Buddhist localhost 서버가 현재 Mac의 Ollama `qwen3:8b`에 연결된다. 기존 Christian 개발 서버, 운영 API, 회원 DB, 키는 읽거나 변경하지 않는다.

## AI 연결의 정확한 기능

AI는 **검증된 대화 안내문 ID를 선택**한다. 자유 문장 생성·경전 생성·교리 상담을 구현한 것이 아니다. 앱과 서버 모두 폐쇄형 응답 스키마를 검사하므로 추가 본문/출처/번역자 필드, 잘못된 종교/단계/템플릿은 거부한다. 경전 인용/마음카드는 기존 BuddhistScriptureProvider의 합성 자료만 사용한다.

앱은 사용자 입력·감정·강도·최근 두 입력을 USB로 연결된 로컬 Mac에 전송한다. 화면에 이 사실을 표시한다. 서버는 대화 내용을 파일/DB/로그에 저장하지 않고 건수만 유지한다. 외부 AI나 OpenAI fallback은 없다. HTTP redirect를 거부하고 Ollama 주소/모델은 고정한다.

Safety는 앱에서 클라이언트 생성 전에, 서버에서 모델 호출 전에 검사한다. 진행 중 위기는 요청을 취소하고 늦은 응답을 버린다. 계정/탭 전환에서도 늦은 결과를 폐기한다. 취소 오류가 나더라도 고정 위기 안내와 인용 제거는 계속한다. 서버는 해당 개발 pairing 동안 위기 상태를 유지한다. 시간 초과·연결 끊김·잘못된 응답에는 기존 고정 안내를 표시한다.

## 개발 연결 실행

```sh
node backend/dev/religion-packs/mac_ai_server.js
```

LISTEN preflight 뒤 OS가 빈 포트를 배정하며 `127.0.0.1`에만 바인딩한다. 출력된 pairing 파일은 OS 임시 폴더에 권한 0600으로 생성된다. 내용은 출력하거나 Git에 넣지 않는다.

```sh
node scripts/android-release.mjs --buddhist-mac-ai <출력된-pairing.json-경로> <USB-기기-serial>
```

기존 Release 설치 엔진을 사용한다. 전용 인증서·패키지·버전·합성 자산을 검사하고 `adb reverse --no-rebind`로 localhost 포트를 연결한 뒤 `adb install -r`만 실행한다. 다른 목적지의 기존 reverse 매핑은 덮어쓰지 않는다. Mac에서 PowerShell이 없어 동일한 Node 엔진을 직접 사용했다.

USB 모드에만 INTERNET과 127.0.0.1 HTTP 예외가 들어간다. APK 리소스 이름 최적화 후에도 실제 network-security-config가 정확히 localhost 예외만 갖는지 검사한다. 기본 `--buddhist` 빌드는 계속 인터넷 권한이 없는 오프라인 앱이다. package·서명키·저장 키는 같아 기존 Buddhist 데이터를 보존한다. Christian 설치 인자/공식 API 경로는 그대로다.

이 APK의 임시 pairing 값은 운영 인증 자격증명이 아니며 일반 배포용 인증 설계가 아니다. **USB 개발 APK는 공개 배포하지 않는다.** USB 연결과 Mac 서버/Ollama가 유지되어야 AI가 작동한다. 서버를 재시작하면 새 pairing으로 다시 빌드/설치해야 한다. 상시 서버/외부 터널/운영 배포는 구성하지 않았다.

## 1~4 재검증 결과

| 항목 | 자동/로컬 검증 | 실기기 상태 |
|---|---|---|
| 1. UI/사용성 | 360px 글꼴 1/2, 감정 선택/키보드 입력/스크롤/대화 진행 PASS; 한글 임시 렌더링 점검 | 사용자 재연결 후에도 Android keyguard showing=true/충전 대기 화면으로 표시되어 실제 화면 검증 대기 |
| 2. 핵심 기능 | 저장·재시작 복원·손상 데이터 보호·공유 미리보기/채널·음성/알림 취소/실패 위젯 테스트 PASS | 실제 공유 선택 UI, TTS 청취, 권한 허용/거절, 알림 도착은 NOT RUN |
| 3. Safety | 위기 클라이언트 생성 0, 모델 호출 0, sticky crisis, 늦은 AI 응답/취소 예외, 임의 경전 출력 거부 PASS | 휴대폰 직접 위기 입력 검증 NOT RUN |
| 4. 회귀/보고 | 아래 테스트와 빌드 PASS, 이 보고서 작성 | 설치 성공과 화면 검증을 구분하며 전체 완료로 표시하지 않음 |

- 변경 전 Buddhist 50 PASS; 최종 57 PASS / analyze clean.
- Christian 전체 125 PASS / 기존 1 SKIP. 기능 변경 뒤 집중 Safety/API 계약 4 PASS 반복 확인.
- backend 작업 트리 420 PASS, 커밋 대상 스냅샷 414 PASS(기존 사용자 Ollama 변경 6건 제외). Buddhist Web E2E 5 PASS.
- 설치 엔진 25 PASS / Windows 전용 1 SKIP. 기본 오프라인 및 USB 네트워크 경계, 기존 인증서/버전/데이터 보존 검사 포함.
- Buddhist 0.3.0+8 USB Release 빌드 및 업데이트 설치 성공. 최종 취소 오류 방어 코드 포함 재설치.
- 기본 오프라인 Release 빌드 PASS, 인터넷 권한 없음·Mock 자산만 포함 검사 PASS. USB APK도 Christian 콘텐츠 혼입 검사 PASS.
- 실제 로컬 모델에 합성 입력 1건: HTTP 200, 약 5.7초, 허용된 `gentleNeed` 템플릿 반환. 이 결과를 휴대폰→서버 E2E 성공으로 간주하지 않는다.
- 빌드 중 Gradle Base64 이름 충돌, APK XML 리소스 압축 경로 검증 실패를 수정했다. 실패 때 설치 엔진이 데이터 삭제 없이 중단했으며 수정 후 재검증했다.
- Christian Android/iOS 새 빌드 NOT RUN: Christian 앱 소스/의존성 미변경, 공유 설치 도구 분기는 단위 테스트로 검증. 운영 API·CI·push·배포 NOT RUN(요청 범위/보류).

## 실제 경전

실제 경전 투입 요청은 받았지만 자료 파일/출처·번역자·라이선스 근거가 아직 제공되지 않았다. 사용자에게 이를 요청했으며 자동 다운로드/수집/복사하지 않았다. 권리 미확인 자료는 `BLOCKED_EXTERNAL_REVIEW`로 처리하고 검색·응답·마음카드 사용을 금지한다. 기존 Provider의 TEST_DATA_ONLY 정책을 우회하거나 실제 자료가 있는 것처럼 표시하지 않았다. 따라서 실제 경전 연동 완료를 주장하지 않는다.

## 후속 확인

사용자가 휴대폰에서 직접 잠금을 풀고 Buddhist 화면을 유지하면 1~3 실기기 항목과 USB AI 왕복을 확인한다. 실제 경전은 제공 자료의 번역 저작권·재배포·앱 내 인용/표시 허용 범위 검토를 먼저 끝내야 한다. Push는 이전 요청대로 보류한다.

기술 근거: [Ollama 공식 structured outputs](https://ollama.com/blog/structured-outputs). 스키마 제약에 더해 앱/서버의 독립 검증을 적용했다.
