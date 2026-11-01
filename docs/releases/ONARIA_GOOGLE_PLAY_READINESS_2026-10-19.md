# ONARIA Google Play 비공개 테스트 등록 준비

작성·확인일: 2026-10-19 (Asia/Seoul)
상태: **AAB24 생성·정적 검사 이력 / 2026-10-22 Alpha·데이터 보안 일부 콘솔 초안 저장 / 심사 전송·테스트 시작 미실행**

최종 기록은 §11(2026-10-22)을 따른다. 앞선 “콘솔 입력 NOT RUN”은 10/19 당시 범위이며 일부 콘솔 저장 후의 현재 상태를 뜻하지 않는다. 전체 고지·SDK·심사 접근 검증은 남아 있다. 2026-10-24 이번 Markdown 대조는 콘솔·운영·기기 상태를 다시 확인하지 않았다.

후속 Build24 AAB 생성·검증은 §10을 따른다. §2의 AAB21은 이번 재생성 전 점검 이력이며, 현재 기본 출력 경로에는 AAB24가 있다.

이 문서는 답변 후보와 실제 확인 증거를 구분한다. `확인 필요`는 콘솔에서 임의로 예/아니오를 선택할 수 없다는 뜻이다. Apple 제출 내역, 과거 기기 성공, 공개 health200은 현재 Play 배포·전체 회원 흐름 성공의 증거가 아니다.

## 1. 근거와 사전점검

| 항목 | 이번 확인값 | 근거·한계 |
|---|---|---|
| 프로젝트 | `/Users/ari/ARI/projects/onaria` | ONARIA만 조회. 불교 버전 등 별도 프로젝트 미변경 |
| 브랜치 | `main` | 과거 codex 작업 브랜치 상태를 재사용하지 않음 |
| HEAD | `75579eddaa83803a6d36ad026bf6e0476470b37a` | main 통합 PR #43의 현재 로컬 HEAD |
| 원격 | `https://github.com/Naharuya/onaria.git` | 원격 쓰기·fetch·병합 없음 |
| 소스 버전 | `1.0.0+24`, package `com.onaria.app` | pubspec.yaml, android/app/build.gradle.kts |
| 기존 변경 | ONARIA_ROADMAP.md 수정 및 .codex/, 사업·마케팅·파일관리 자료, 차기 기획·호스팅 이전 준비 문서, 구형 build20 스크립트 등 미추적 파일 | 기존 변경 보존. 이번 산출물은 본 문서뿐 |
| Play 현재값 | 내부 테스트 `0.4.1 / versionCode 7`, 앱 설정 미완료 | 2026-10-19 사용자 제공. 콘솔 직접 조회·바이너리 내려받기는 미실시 |
| 최신 기획 | ONARIA_MASTER_PRODUCT_PLAN, ONARIA_ROADMAP, 10/12 신앙 선택·다국어 계획 | 현재는 성경 기반 한국어 경험. 개신교/가톨릭 선택·다국어·7종교 전체 지원을 현재 출시 기능으로 쓰지 않음 |
| 최신 릴리스 | Build24 main source manifest, MAIN_INTEGRATION, STORE_PRIVACY_FOLLOWUP, RETENTION_IMPLEMENTATION | 후속 기록을 우선. 과거 체크리스트의 Build19·보유기간 미정·Apple 미제출 표시는 오래된 상태 |
| 클라이언트 일치 | Build24 source manifest의 165개 파일 모두 현재 파일 SHA256 일치, 누락 0 | manifest 범위의 소스 일치이며 현재 AAB의 소스 증명은 아님 |

AGENTS.md, docs/ARI_COMPLIANCE_STANDARD.md, pubspec.yaml, backend/package.json, 기존 스토어 설명·체크리스트·Android 배포 문서를 읽었다. 운영 서버 설정·DB·세션·키 값은 조회하거나 변경하지 않았다. 임시 HTML/검사 결과와 테스트 로그는 `/tmp/onaria-play-*`에 보관하며 본 문서에 인증정보는 넣지 않는다.

## 2. 소스·산출물·Play 등록본의 차이

| 대상 | 확인한 실제 값 | 판정 |
|---|---|---|
| 최신 소스 | 1.0.0+24. 회원별 기록, 초기 입력 최소화, fresh owner proof, 탈퇴 후 기기 정리, 선택 회원통합 코드. 통합은 서버에서 허용할 때만 노출 | 소스 확인 PASS. 운영 merge 활성·실제 동작은 이번 미검증 |
| 남아 있는 APK | `build/app/outputs/flutter-apk/app-release.apk`: 1.0.0 / 24 / com.onaria.app | aapt 읽기 PASS. 이번 설치·실행 없음 |
| 남아 있는 AAB | `build/app/outputs/bundle/release/app-release.aab`: **1.0.0 / 21**, com.onaria.app, minSdk24, target/compile36 | AAB 내부 protobuf manifest 직접 읽기. **Build24 AAB가 아님** |
| AAB SHA256 | `98c0594eeae6775c13e6bfb6aa9d361c11efb8d27df62b20f3750c009683f886`, 61,723,264 bytes | 현재 파일을 식별하는 값. 최신 소스·Play 업로드 적격 검증 완료를 뜻하지 않음 |
| Play 내부 테스트 | 0.4.1 / 7 | 사용자 확인만. Build7 AAB/APK·소스·SDK 목록 미확보로 세부 기능 diff는 BLOCKED |
| 공개 API health | HTTP200, status ok / version1.0.0 / build20 | 응답 표기만 확인. app.js 기본 build20 fallback이 있으므로 실제 배포 소스가 Build20이라고 단정하지 않음 |

**결론:** 최신 소스24·로컬 APK24·로컬 AAB21·Play7을 구분한다. 기존 AAB21을 최신 검증 AAB로 제출하지 않는다. 승인된 다음 단계에서 최신 소스와 보호 설정으로 Release AAB를 재현하고, 실제 manifest·서명·SHA·빌드 로그·ABI/네이티브 및 16KB 페이지 크기 대응을 검사해야 한다. 이번에는 재빌드·번호 변경·업로드를 하지 않았다. 모든 트랙 최고 versionCode는 제출 직전 다시 확인한다.

### 2.1 업로드 인증서와 Play 앱 서명 인증서

초기 기록의 `android/soul-bible-release.jks`는 AGENTS의 구형 경로다. 후속 점검에서 해당 파일이 없고, 실제 `android/key.properties`는 기존 secure 영역의 onaria-upload.jks를 참조함을 확인했다. 교체 없이 그 설정을 재사용했으며, 비밀번호는 기존 설정에서 프로세스 내부로만 전달하고 출력·새 파일 저장하지 않았다. 아래는 처음 AAB21에서 읽은 공개 인증서 지문이며, 최신 AAB24도 동일함을 §10에서 확인했다:

- SHA-1: `6F:F3:39:0B:79:7B:24:DB:9D:2C:8A:79:B1:62:77:55:D7:0D:19:F7`
- SHA-256: `97:2A:E4:64:5E:3C:7C:93:FC:4D:38:58:25:0D:E1:A3:AF:93:C5:14:38:6C:5D:65:40:EF:D5:16:52:CD:3D:07`

이는 **로컬 Release/AAB 서명 인증서**다. Play Console의 업로드 인증서와 대조 전에는 동일한 업로드 키라고 확정하지 않는다. Play는 AAB 업로드자를 업로드 인증서로 확인하고 실제 배포 APK를 앱 서명 키로 서명한다. 두 인증서가 같다는 가정은 금지한다. [Google 공식 서명 설명](https://developer.android.com/studio/publish/app-signing), [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756).

| 대조 대상 | 필요한 확인 | 현재 상태 |
|---|---|---|
| Play 앱 무결성 | 업로드 인증서 SHA1/SHA256 및 앱 서명 인증서 SHA1/SHA256, 키 업그레이드 시 각 OS별 인증서 | **BLOCKED** — 콘솔 공개 지문 화면 필요. 개인키 파일은 필요 없음 |
| Google | com.onaria.app + **Play 앱 서명 SHA1**의 Android OAuth client, 앱의 serverClientId와 서버 Google audience 일치, OAuth 테스트 사용자/게시 상태 | 로컬 client/serverClientId 설정 존재. 콘솔 및 현재 서버 audience는 미확인. 직접 설치 Google 성공으로 대체 불가. [공식 인증서 안내](https://developers.google.com/android/guides/client-auth) |
| 카카오 | Play 앱 서명 인증서 SHA1의 원시 바이트를 Base64한 키 해시 등록, 패키지·native app 설정, OIDC/audience, 동의항목·개발모드 제한 | 보호 설정 참조와 nonce 기반 로그인 코드 존재. Play 키 해시 등록·서버 audience 미확인. **hex 문자열 자체의 Base64와 혼동 금지**. [공식 키 해시 안내](https://developers.kakao.com/docs/en/android/getting-started) |
| 네이버 | Android 앱 등록 package·클라이언트 매칭·서비스/검수 상태, 제공자 앱 유무·Chrome 복귀. 콘솔에서 요구하는 등록 항목만 대조 | 프로젝트 포크 및 Nid OAuth5.11.2 사용. 임의 SHA 등록 요구를 만들어내지 않음. 현재 보호값 대조·Play 설치본 E2E 미실시. [공식 가이드](https://developers.naver.com/docs/login/android/android.md) |
| Apple Android | Service ID, 서버 audience, 전체 HTTPS callback, signinwithapple 복귀, Android intent 처리 | 기존 코드 경로 존재. 이번 콘솔/운영 설정 최신 대조·실제 인증 NOT RUN |
| Android App Links | api.onaria.ai.kr/.well-known/assetlinks.json의 com.onaria.app + Play 앱 서명 SHA256 | 이번 GET200이지만 목록 `[]`. HTTPS /app/open 검증 자료 없음. 소셜 callback 전부 실패한다는 의미는 아님. 공유 앱 링크 배포 시 별도 Gate |

기존 인증서는 교체하지 않는다. 콘솔·provider 설정 변경과 실제 인증은 이번 작업 범위에 없다.

## 3. 실제 데이터·SDK·권한과 고지 대조

### 3.1 데이터 흐름 및 Data safety 입력 후보

Google Play는 앱 밖으로 전송되는 일시 처리 데이터도 양식 답변에서 검토하도록 한다. Apple에서 Other User Content를 제외했던 ‘서버에 영구 저장하지 않음’ 근거만으로 Play에서 수집 안 함을 선택하면 안 된다. Android SDK의 자동 처리도 포함해야 하며, iOS 개인정보 매니페스트 11개 유형을 Android 정답으로 복사하지 않는다. [Google Data safety 정의](https://support.google.com/googleplay/android-developer/answer/10787469).

아래는 소스 기반 후보다. `공유 확인 필요`는 임의로 ‘공유 안 함’ 또는 ‘공유함’을 제출하라는 뜻이 아니다. 제공자 역할·서비스 제공 계약·사용자 주도 전송 등 Google 예외의 실제 해당 여부가 필요하다.

| 실제 항목 / Play 유형 후보 | 수집·전송 / 선택성 / 목적 | 보관·삭제·공유 판단 |
|---|---|---|
| 회원/소셜 고유 ID → 개인정보: 사용자 ID | 소셜 로그인 선택 시 필수. 제공자→앱→ONARIA; 인증·계정 관리·보안 | member_identities, 세션. 탈퇴/폐기 경로 존재. 공급자 자체 보관·제3자 공유 예외는 확인 필요 |
| 이름·전화 → 개인정보: 이름/전화번호 | 선택 입력을 저장하는 스키마 존재; 초기 가입에서 필수 입력 아님 | member DB. 입력한 경우 탈퇴 대상. SDK 동의 화면에서 별도 처리될 항목은 추가 확인 |
| 교회명/신앙 내용 → 개인정보: 종교적 신념 및 기타 민감 정보 | 선택 교회정보 저장; 자유 입력 문장에도 포함 가능. 계정 기능/성찰 | member DB 또는 일시 요청. 자동 종교 선택 수집은 아직 미구현. 민감정보 수집 없음을 주장하지 않음 |
| 선택 감정·강도·성찰 문장/최근 맥락 → 건강 및 피트니스: 건강 정보, 기타 사용자 제작 콘텐츠 후보 | 동의 후 POST /v1/mind/chat. 앱 기능. 전송 허용은 선택이나 서버 대화 사용에는 필요 | schema/session/userMessage/conversationMemory. 서버 요청 내 일시 처리임을 검토하되 로그·오류·제공자까지 포함한 일시 처리 요건 미확정. 두 유형의 적용 범위 확인 필요 |
| OpenAI 요청 → 위 대화/민감 내용 유형의 외부 처리 | 서버 OpenAI 활성 조건과 앱 동의 모두 충족 시. `store:false` | 현재 운영 모드는 **이번 미확인**. 10/11 local 모드는 과거 증거. store:false가 무보관·무국외처리를 뜻하지 않음. 계약·지역·보관·재위탁·공유 예외 확인 전 최종 제출 보류 |
| 접속 IP·시각·경로·상태·크기·지연 → 기기/기타 ID·진단·앱 성능·앱 상호작용 후보 | HTTP 접속 시 운영 보안/안정성/성능. 일부 경로는 사용자 선택과 무관하게 발생 | 공개 정책 14일 및 일일 정리. IP를 수집한다고 정밀 위치를 수집하는 것은 아님. IP→대략 위치 유도/SDK 처리 여부는 별도 확인 |
| 가명 사용량 ID·토큰수·비용 → 사용자 ID 또는 기기/기타 ID, 앱 상호작용·기타 행동 후보 | 사용 한도·비용 제어; 고정 가명 ID는 자동 익명으로 간주하지 않음 | 원장62일. member 소유권과 과거 별도 사용량 식별자 매핑·탈퇴 예외를 확인해야 함 |
| 개선 의견 평가·이유·submissionId → 앱 상호작용/기타 사용자 제작 콘텐츠 후보 | 내 기록→개선 의견 보내기. 선택 전송. 개발자 분석/제품 개선 | feedback_page.dart 및 feedback.js: 원문·감정·회원정보 없이 평가/이유를 메모리 집계, bounded 중복 방지 ID. 프로세스 재시작 시 집계 초기화. proxy IP 로그는 별도. 공개 정책에 의견 항목 설명 보완 필요 |
| 마이크 음성 → 오디오 파일/음성 또는 음성 녹음 후보 | 선택 음성 입력→OS speech provider, 텍스트 결과를 앱에 반환 | ONARIA 음성 업로드·녹음 DB 없음. Android 인식 서비스가 외부 처리하는지 설정/기기/provider 증거 미확보이므로 ‘오디오 수집 안 함’ 최종 선택 보류 |
| TTS 텍스트 → 사용자 콘텐츠 후보 | 선택 읽어주기→OS TTS 서비스 | ONARIA 자체 음성 보관 없음. OS/provider의 온라인 엔진 처리 확인 필요 |
| 마음카드·저장 말씀·초안·여정·감정 집계·알림·AI 동의 | 기기 SharedPreferences 회원/guest namespace. 공유 선택 시 OS share sheet로 이미지/텍스트 전달 | 정상 저장만으로 서버 수집으로 보지 않음. 계정 삭제 시 해당 owner 정리, 기존 소유 미확정 기록·다른 계정·다른 기기·OS 백업 제외. OS 자동백업·암호화·철회 후 이미 공유한 사본은 별도 |
| 이메일·기기 ID·대략 위치·진단·SDK 사용 데이터 | ONARIA member DB의 해당 열 유무와 Google/카카오/네이버 SDK 자동 수집은 별개 | **Android SDK별 최종 정보 필요**. iOS GoogleSignIn 선언을 Android 수집 증거로 단정하지 않음. 미확인 항목 ‘없음’ 제출 금지 |
| 사진/연락처/정밀 위치/결제/금융 데이터 | 현재 직접 처리 기능·권한·광고/결제 SDK는 확인한 범위에서 발견 안 됨 | OS 공유·소셜 제공자 기능 전체에 수집 없음으로 확대하지 않음. Build7은 별도 미확인 |

[Google SDK 공개 안내](https://developers.google.com/android/guides/play-data-disclosure)는 base/basement/tasks 등의 범위만 다루므로 이것만으로 Google 로그인 전체 ‘수집 없음’이라 판단하지 않는다. pubspec/lock, Naver Android build.gradle, merged-manifest report를 확인했다. Android native 보고서에서 Google play-services-auth21.6.0과 Nid OAuth5.11.2가 보이지만, 최신24 AAB 부재로 최종 번들 내 모든 SDK 버전 확정은 보류한다. backend lock의 Sentry 이름은 개발 도구 전이 의존성 흔적일 수 있어 실제 앱 분석 SDK 사용으로 단정하지 않는다.

### 3.2 Android 권한

소스 main manifest 및 현재 남은 AAB21의 실제 manifest에 아래 권한이 있다. 최신24 merged manifest에도 같은 종류가 있으나 이것을 최신24 AAB 검사로 대체하지 않는다.

| 권한 | 실제 목적 / 고지·검증 사항 |
|---|---|
| INTERNET / ACCESS_NETWORK_STATE | API·소셜 인증과 네트워크 상태. 전송 데이터별 고지 필요 |
| RECORD_AUDIO | 사용자가 고른 음성 입력. 거부하고 텍스트 사용 가능. OS 음성 처리 경로 확인 필요 |
| BLUETOOTH / BLUETOOTH_ADMIN(max30), BLUETOOTH_CONNECT | 음성·오디오 장치 관련. 실제 기능상 필요성과 runtime 요청은 최종 AAB/기기에서 재검토 |
| RECEIVE_BOOT_COMPLETED / VIBRATE / POST_NOTIFICATIONS | 로컬 알림·재부팅 후 예약 복구·진동. 푸시서버 수집으로 단정하지 않음 |
| USE_BIOMETRIC / USE_FINGERPRINT | 의존성 병합. 실제 얼굴/지문 원본을 ONARIA 서버로 수집하는 증거 아님. 보안저장소·로컬 확인 사용 범위 확인 |
| com.onaria.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION | 동적 receiver 보호용 자체 signature 권한. 사용자 데이터 유형 아님 |

확인한 manifest에 AD_ID, 위치, 연락처, SMS/통화, 저장소 광범위 접근, Health Connect, Billing 권한은 없다. AAB21에는 debuggable 속성 명시가 없어 Android 기본 false로 해석된다. 최신24 AAB의 debuggable/네트워크 보안/allowBackup·자동백업 규칙은 재생성 후 별도 확인해야 한다. Release API는 HTTPS DNS 검증, 리다이렉트 거부이며 운영 주소는 api.onaria.ai.kr이다.

## 4. Play Console 11개 항목 입력 초안

### ① 개인정보처리방침
- 입력 URL: **https://onaria.ai.kr/privacy**
- 운영자·문의: 공개 정책에 적힌 조세진 / 공개 고객지원 이메일 `vjsjv7003@gmail.com`. 계정 로그인 ID·비밀번호를 뜻하지 않는다.
- 초안: “ONARIA는 소셜 인증·선택 프로필, 동의 후 전송한 감정·대화, 운영 접속·사용량 정보를 처리합니다. 기기 기록과 OS 음성·소셜 제공자 처리를 구분하고, 앱 내 본인확인 탈퇴 및 앱 밖 삭제 문의 방법을 제공합니다.”
- 상태: URL PASS. 외부 AI 활성·국외 처리 조건, Android SDK 세부 수집, 의견 전송 항목, 실제 운영 보유/삭제 현행성을 보완·재확인한 뒤 최종 적합 판정. ‘데이터를 전혀 수집하지 않음’ 입력 금지.

### ② 로그인 세부정보 / 앱 액세스
- 선택 초안: **모든 기능 또는 일부 기능에 접근 제한이 있음**. 기본 체험은 비로그인 가능하지만 계정·연결·탈퇴는 로그인 필요. Apple 심사 메모의 로그인 불필요 체크를 그대로 복사하지 않음.
- ONARIA 자체 공용 ID/password 로그인은 없다. 심사자에게 개인/운영자 소셜 계정이나 인증 토큰 제공 금지.
- 계정 없이 접근하는 절차와 소셜 제한 기능은 아래 §6의 심사 안내를 사용.
- 상태: 안내 초안 PASS / **전체 계정 기능 접근 방법 BLOCKED**. Google 공식 기준상 제한된 모든 기능 접근을 제공해야 하므로 핵심 화면만 열리는 것으로 완료 표시하지 않음.

### ③ 광고
- 입력 후보: **아니요, 광고를 포함하지 않음**.
- 근거: pubspec/앱 권한·소스에서 광고 SDK·광고 지면·AD_ID 없음. 자체 기능 소개와 광고를 혼동하지 않음.
- 확인 필요: Play7 및 최종 AAB24의 SDK 목록과 실제 노출. 수익모델 계획·가명 사용량만으로 광고 있음으로 답하지 않음.

### ④ 콘텐츠 등급 (IARC)
- 이메일: 공개 고객지원 이메일 후보. 앱 종류는 실제 선택지에서 일반 앱/라이프스타일 기반으로 확인.
- 응답 준비: 사용자간 공개 채팅·게시판·공개 UGC 없음; 도박/실제 현금 보상/금융 거래 기능 없음; 성경 말씀·감정 성찰·1인 대화·미니게임 포함.
- 위기·자해/정서적 고통에 대한 안전 안내와 자유입력·AI 상호작용이 있다. ‘민감 주제 전혀 없음’으로 일괄 답하지 않는다. 각 질문의 묘사/언급/빈도 정의에 맞춰 실제 구절과 응답·안전문구를 검토해야 한다.
- **등급은 질문 완료 후 IARC 산출**. 타겟18+ 또는 Apple 등급을 IARC 결과로 쓰지 않음. 미응답 질문/산출 등급은 확인 필요.

### ⑤ 타겟층 및 콘텐츠
- 입력 후보: **만18세 이상만**. 아동·청소년 대상 체크 안 함.
- 근거: terms의 성인 정책, 회원가입 및 대화 전송 동의의18세 자기 확인. 공인 연령/본인 인증이 아니라 자기 확인임을 구분.
- 공개 탐색은 계정 없이 가능하므로 앱 전체가 강력한 연령 검증으로 차단된다고 주장하지 않는다. 아동 대상 그래픽·키워드로 홍보하지 않음.
- 배포 국가/계정별 추가 연령 요구·콘솔 선택지는 사용자 확인. 계획상 다국어·가톨릭 기능을 현행 지원으로 입력하지 않음.

### ⑥ 데이터 보안 (Data safety)
- “필수 데이터 유형을 수집하거나 공유하는가”: **예 후보 — 수집은 확실**, 공유 유형/예외는 §3에서 확인 후 선택.
- 전송 중 암호화: ONARIA 경로 HTTPS 확인. **전체 SDK 경로를 포함한 최종 ‘예’는 provider 보안 확인 필요**. 이를 기기 저장 암호화와 혼동하지 않음.
- 계정 생성 방식: **OAuth/소셜 로그인**(Google·네이버·카카오·Apple). 자체 사용자명+비밀번호 생성 없음. 전화번호는 선택 프로필이며 휴대폰 OTP 계정 생성이 아님.
- 계정 삭제 URL: **https://onaria.ai.kr/account-deletion**. 앱 내 계정 관리→회원탈퇴. 앱 밖 공개 문의 절차 존재.
- 계정 삭제 없이 일부 데이터 삭제: 개인정보와 기록 관리의 마음카드·말씀·초안 및 AI 동의 철회 등 실제 제공 범위만 설명. 서버 원장/로그 즉시 삭제 선택이 있는 것처럼 입력 금지.
- 데이터별 수집/공유/일시 처리/필수·선택/목적: §3.1 표를 근거로 입력. 앱 기능·계정 관리·보안·분석을 구분. 광고 목적은 증거 없음.
- 독립 보안 검토·배지: **NOT RUN**, 인증 보유 주장 금지.
- 현재 Play7에서 계속 배포되는 기능도 양식 범위에 포함되는지 트랙/정책 안내를 확인. 과거 바이너리 미확보 및 SDK·운영 흐름 미확인으로 최종 제출 BLOCKED.

### ⑦ 정부 앱
- 입력 후보: **아니요**. ONARIA는 정부기관 서비스나 공식 정부 대행으로 표시하지 않음.
- 근거: 일반 신앙·마음 성찰 앱이며 정부 인증/공식 제휴 주장 없음. 법적 운영주체는 개발자 계정 프로필과 대조 필요.

### ⑧ 금융 기능
- 입력 후보: **금융 기능을 제공하지 않음**.
- 근거: 은행·대출·투자·암호자산·송금·금융자문 기능 없음. AI 비용 원장은 개발자 운영 비용이며 사용자 금융 기능이 아님. 현재 결제·구독 기능도 없음.
- 확인 필요: 최종 AAB 및 Play7. 향후 프리미엄 계획을 구현된 금융 기능으로 입력하지 않음.

### ⑨ 건강
- **‘건강 기능 없음’ 자동 선택 금지**. 기능상 감정 성찰·스트레스 완화·자기 돌봄이 있으므로 권장 후보는 **스트레스 관리·이완·정신 능력(Stress Management, Relaxation, Mental Acuity)**.
- 정신건강 지원에 해당하는 실제 대화 범위라면 **정신 및 행동 건강(Mental and Behavioral Health)**도 추가 검토. 현재 clinical_reflection 모드·정서적 지원 문구를 근거로 콘솔 정의와 대조하고 확정한다. 의료기기/진단/치료 기능을 주장하지 않는다.
- 설명 초안: “현재 마음을 기록하고 성찰 질문·성경 말씀·작은 실천으로 일상적 자기 돌봄을 돕습니다. 의료적 진단·치료·전문 상담을 제공하지 않습니다.”
- Health Connect·병원/의료인 연계·임상연구 권한/기능은 발견 안 됨. 해당 없음 답변은 최종 범위 재확인 후.
- 근거: [Google 건강 기능 신고 기준](https://support.google.com/googleplay/android-developer/answer/14738291). 비의료 고지나 Lifestyle 카테고리만으로 건강 신고 대상에서 제외되지 않는다.

### ⑩ 카테고리·연락처
- 앱/게임: **앱**(부가 미니게임이 주 기능 아님).
- 카테고리 권장: **라이프스타일**. 건강 기능 신고와 별개. 태그는 실제 콘솔에서 묵상·일기·자기 돌봄에 맞는 항목만 선택.
- 지원 이메일: 공개된 `vjsjv7003@gmail.com`; 웹사이트 https://onaria.ai.kr; 지원 https://onaria.ai.kr/support.
- 공개 전화번호·주소, 개발자 법적 실명/사업자/판매자·배포 국가별 필수 프로필은 **확인 필요**. 임의 생성하지 않음. 개인정보처리방침 운영자와 개발자 계정 표기가 다르면 정합성 확인.
- 현재 무료/앱 내 결제 없음이 공개 약관과 일치. 무료/유료 전환·상업적 계획 확정이나 콘솔 변경은 하지 않음.

### ⑪ 스토어 등록정보
- 기본 언어: **한국어(대한민국)** 후보. 앱 이름: **ONARIA**.
- 짧은 설명 초안(80자 이내): **감정과 말씀, 작은 실천으로 하루의 마음을 돌아보는 신앙 기반 마음관리 앱**
- 전체 설명 초안:

> ONARIA는 지금의 감정과 강도를 살펴보고, 성찰 대화와 성경 말씀, 오늘 할 수 있는 작은 실천으로 하루를 돌아보는 앱입니다.
>
> • 감정 체크인과 직접 입력
> • 마음을 돌아보는 질문과 성경 말씀
> • 작은 실천, 마음카드 저장·공유
> • 7일 마음의 여정과 성장 기록
> • 선택형 알림과 십자가 미니게임
>
> 기본 마음 살펴보기를 로그인 없이 시작할 수 있습니다. 계정 기능은 네이버·Google·카카오·Apple 인증을 이용합니다. 음성 입력과 대화 전송은 사용자의 선택에 따라 이용합니다. 대화 응답 방식과 외부 AI 사용 여부는 안내와 서비스 설정에 따릅니다. 외부 AI가 활성화된 경우에는 전송 안내와 동의를 확인합니다.
>
> ONARIA는 의료적 진단·치료·전문 상담 또는 종교기관의 공식 자문을 대신하지 않습니다. 긴급한 위험이 있다면 앱의 답변을 기다리지 말고 현실의 도움을 우선해 주세요.
>
> 개인정보처리방침: https://onaria.ai.kr/privacy
> 고객지원: https://onaria.ai.kr/support
> 계정 및 데이터 삭제: https://onaria.ai.kr/account-deletion

- 재사용 출처: docs/STORE_LISTING_COPY_KO.md. 오래된 ‘소셜 준비 중’·항상 실제 외부 AI·3분 완료 보장·현재7종교/성경 전체/다국어 지원 표현은 채택하지 않음.
- 내부 테스트 릴리스 노트 후보: “마음 성찰과 말씀·기록 기능 및 소셜 계정 경험을 점검하는 비공개 테스트입니다. 오류는 앱의 개선 의견과 고객지원으로 알려주세요.” 빌드24가 확정되기 전 버전/기능을 콘솔에 저장하지 않음.
- 이미지별 캡션: “오늘 마음은 어떤가요?”, “천천히 마음을 돌아보는 대화”, “말씀과 작은 실천”, “내 마음의 기록”, “7일 마음의 여정”. 실제 Android 화면이 보여주는 기능과 일치해야 함.

## 5. 개인정보·지원·계정삭제 URL 실측

2026-10-19 인증 없는 HTTPS GET, 표준 TLS 검증 유지. 웹 조회 도구는 오류가 났지만 로컬 HTTPS GET 재확인으로 모두200을 확인했다. 인증 우회·관리자 접근·POST는 없다.

| URL | 결과 / 제목 | 공개 HTML SHA256 |
|---|---|---|
| https://onaria.ai.kr/privacy | 200 text/html; 개인정보 처리 안내; 메일 문의 링크,14일/62일 포함 | fb9ca805cf4eabd8f00cebac729ea82cd0e14922186c0aabaa39cc22a1ed3036 |
| https://onaria.ai.kr/support | 200 text/html; 고객지원; 계정삭제·정책 링크/문의 존재 | 83a1b751292533002a6ab11030ecea4a4eea7613fe934dd01a068ba6e5f980ce |
| https://onaria.ai.kr/account-deletion | 200 text/html; 계정 및 데이터 삭제; 앱 안/밖 절차와 보유 예외 | a53af130640b6541750232e4e05d29f33cef4196abdcadf916d79b29dbdb1257 |
| https://onaria.ai.kr/terms | 200 text/html; 이용 안내;18세 이상·무료·비의료 고지 | 2137309a7d8309c4654d3a796573c01bfb53ffb984d626253e063ef00f9c3899 |

### 고지와 구현의 일치·남은 차이
- **일치:** 선택 프로필, 로그인 제공자 ID, 서버로 전송하는 대화/감정, 기기 기록, 음성 텍스트 선택, 탈퇴 전 owner/Apple proof, 서버 성공 후 해당 계정 기기 cleanup, 다른 회원/기기/OS 백업 제외.
- **보유기간:** 공개 정책은 일반 로그/정기 백업14일+다음 일일 파기, 원장62일, 세션최대30일, 최소 삭제 명부14일과 restore barrier를 고지. 기존 소스·10/11 운영 실행 기록이 있으며 이번 격리 테스트도 통과. **10/19 운영 timer·외부 사본·실행 실패 여부는 조회하지 않아 현재 운영 전수 PASS 아님.** 과거1년/30일·37일 후보를 적용하지 않음.
- **앱 밖 삭제:** 공개 페이지가 ONARIA 이름·삭제 절차·문의·보유 예외를 제공하며 이메일로 요청을 시작할 수 있다. 익명 자동 삭제 폼은 없다. [Google 계정 삭제 요건](https://support.google.com/googleplay/android-developer/answer/13327111)에 맞는 요청 경로 후보지만 문의 접수·안전한 본인확인·실제 처리·처리 안내 SLA는 이번 E2E 미검증이다. 계정 없이 접근200만으로 삭제 요건 전체 PASS라고 하지 않음.
- **외부 AI:** 앱은 OpenAI와 항목·동의·store:false의 한계를 설명한다. 공개 정책은 실제 국가·보관조건 등이 준비된 뒤 사용해야 한다는 조건부 문구다. 현재 활성 설정 및 국외 처리 고지가 미확인이라 실제 활성이라면 정책/동의·Data safety 보완이 선행되어야 한다. ‘런칭 후6개월’은 도입 확정 시점으로 쓰지 않음.
- **SDK:** 공개 정책의 Google iOS 매니페스트 설명을 Android SDK 검증으로 취급하지 않음. Android 서비스별 공개 자료·제공자 콘솔 동의항목이 필요하다.
- **의견 전송:** 선택 평가·이유/메모리 집계는 구현돼 있지만 공개 정책에 구체적인 설명이 없다. 전송 목적·항목·보관(메모리 집계/별도 접속 로그)을 반영하는 고지 보완안이 필요. 이번 운영 고지 변경 없음.
- **AI 신고:** 앱의 ‘내 기록→개선 의견 보내기’는 helpful/not_helpful과 고정 이유만 전송하며 특정 답변/부적절함의 신고·처리 상태를 전달하는 전용 UI는 확인되지 않는다. 이것만으로 Google AI 신고 요구 충족 PASS라고 하지 않음. 외부 생성형 기능을 배포한다면 인앱 flag/report 기능·접수·처리 검증이 필요. [Google AI 정책](https://support.google.com/googleplay/android-developer/answer/14094294), [공식 인앱 신고 안내](https://android-developers.googleblog.com/2024/06/enabling-safe-ai-experiences.html).

## 6. 심사자가 핵심 기능에 접근하는 방법

### 계정 없는 핵심 흐름 안내 초안

1. ONARIA를 열면 홈에서 ‘오늘 마음은 어떤가요?’의 감정과 강도를 선택합니다.
2. ‘AI 마음대화 시작하기’로 이동하여 선택 예시 또는 짧은 문장으로 성찰을 시작합니다. 음성 권한은 거부하고 텍스트로 이용할 수 있습니다.
3. 서버로 보내는 경우18세 이상 확인 및 전송 항목 안내를 보고 허용할 수 있습니다. 거절하면 전송하지 않습니다. 허용은 실제 외부 AI 활성화를 보장하지 않습니다.
4. 대화·말씀·작은 실천을 확인하고 마음카드를 저장합니다. 메뉴/내 기록에서 카드·여정·성장 기록과 선택 알림을 확인합니다.
5. 계정 기능은 메뉴→로그인에서 지원하는 소셜 인증이 필요합니다. 계정 관리·연결·탈퇴는 아래 별도 접근 준비 대상입니다.

심사 메모용 영어 초안:

> Basic check-in, reflection, scripture, practices and local records can be explored without an ONARIA account. Select an emotion and intensity on the home screen, then start the conversation. Microphone permission is optional. Sending text to the server requires the in-app adult confirmation and data-transfer choice. External AI use depends on service configuration; a successful local response is not proof of a live external AI call. Account management, linked sign-in methods and account deletion require social authentication. ONARIA does not provide a shared native username/password login.

### 제한 기능 접근 준비 — BLOCKED

- 실제 제공자 약관·Google 심사 조건에 맞는 **전용 심사용 테스트 계정/접근 방법**을 준비한다. 개인 계정·운영자 계정은 쓰지 않는다.
- 비밀번호·OTP·토큰·복구 코드·쿠키를 Git/이 문서/채팅으로 요청하거나 넣지 않는다. 필요한 심사용 자격증명은 적법하게 준비된 후 사용자 본인이 Play의 보안 입력란에서만 관리한다.
- 심사자 자신의 소셜 로그인 허용이 충분한지 현재 Play 앱 액세스 화면 지침에서 확인한다. 개발모드 테스트 사용자/지역·기기 제한·2단계 인증으로 막히지 않는지 검증한다. 불가능하면 승인된 별도 심사 접근 설계가 필요하며 운영 auth 우회·마스터 계정은 만들지 않는다.
- 본인 계정 탈퇴 시험에는 심사용 전용 데이터만 사용하고 실제 회원/운영자 계정은 제외한다. 이번에는 계정 생성·로그인·삭제 실행 없음.

## 7. 기존 이미지·설명 재사용과 부족 자료

| 기존 자료 | 실제 확인 | 재사용 판단 |
|---|---|---|
| docs/STORE_LISTING_COPY_KO.md | 한국어 짧은/전체 설명·캡션·카테고리 후보 | §4의 현행 기능·조건부 AI 표현으로 정리하여 재사용 |
| assets/images/logo.svg 및 앱 아이콘 | 기존 브랜드 벡터·iOS 아이콘1024×1024 존재 | 원본 재사용 가능. Play용512×512 PNG 최종본은 확인 못함 |
| docs/marketing/blog/naver_blog_setup/onaria-emblem.svg.png | 600×600 RGBA | 브랜드 원본 후보. 바로512 규격 완료로 기록하지 않음 |
| 같은 폴더 onariabanner.png / onariaprofile.png | 966×320 RGB / 320×320 RGB | 1024×500 feature graphic·512아이콘 규격과 다름 |
| build/app-store-submission/screenshots/iphone/01-check-in.png | 1206×2622 RGBA | iPhone 자료; Android 실제 화면 증거로 쓰지 않음 |
| 같은 경로 ipad/01-check-in.png | 2064×2752 RGBA | iPad 자료; Android 태블릿 증거 아님 |
| build/onaria-web-results 및 starlight 이미지 | 웹/관리자 테스트 화면 다수 | Android 스토어 스크린샷으로 쓰지 않음 |
| Apple 콘솔 기존5장 기록 | 10/11 제출 기록에 존재, 로컬 해당5장 세트 미확보 | 현재 Android와 동일 화면·최신성 확인 전 재사용 보류 |

부족 자료:
- Play용 고해상도 아이콘512×512 PNG, feature graphic1024×500 PNG/JPEG. 기존 로고로 제작할 수 있으나 이번 작업은 자료 조사·초안이며 생성하지 않음. Android launcher 아이콘은 최대192×192, foreground는432×432로 Play512 최종 자산이 아니다.
- **최소2장**의 실제 최종 Android 휴대폰 스크린샷(감정/대화/말씀·실천/기록 권장4~5장). 통지·계정명·개인 기록을 제거한 테스트 데이터로 촬영. 이미지 규격/최대장수·프로모션 요건은 [Google 자산 기준](https://support.google.com/googleplay/android-developer/answer/9866151)에서 확인.
- 태블릿을 타겟 배포하면 실제 Android 태블릿 레이아웃/화면이 필요. 현재 iPad 화면으로 대신하지 않음.
- 이번에는 기기 설치/조작/캡처·새 이미지 생성·콘솔 자산 업로드 없음. 모델로 만든 가짜 기능 화면을 실제 스크린샷으로 쓰지 않음.

## 8. 미확인 항목과 다음 단계

### 우선순위와 완료 조건

| 우선 | 미완료 Gate | 필요한 다음 행동 / 통과 조건 |
|---|---|---|
| P1 | 최신 AAB 정적 Gate 해소, 실행 Gate 남음 | §10에서24 AAB 생성·정적 검사 완료. 16KB 환경 실행·Play7 상세 diff·Play 실제 배포본 인증은 미검증 |
| P1 | Play 서명·소셜 로그인 | 사용자 Play 앱 무결성에서 공개 인증서2종 확인, provider 설정 대조. 이후 별도 승인된 Play 테스트 설치본으로 인증/복귀/기존 회원 확인 |
| P1 | Data safety·건강 신고 | Android SDK 공개 처리 문서·현재 운영 외부 AI/음성 처리·원장 식별자·공유 예외 확인, 건강 기능 범위 확정. 모든 ‘확인 필요’ 해소 |
| P1 | 심사 전체 접근 | 개인/운영 계정 없이 제한 기능 접근 방법을 준비하고 실제 심사 조건으로 검증 |
| P1 | 고지·삭제·AI 신고 | 공개 의견 처리 설명, 활성 AI라면 국외·제공자 처리 고지 및 인앱 부적절 답변 신고 경로 검증, 앱 밖 삭제 요청 처리 확인 |
| P2 | 등록 자산·법적 사실 | Android 실제 화면/규격 이미지·지원 연락처·개발자 프로필·배포 국가·IARC 질문 완료 |
| 이후 | 비공개 트랙 설정 | 사용자 직접 인증 후 콘솔11항목 검토, 테스트 그룹/초대 방식·국가·참여 URL·릴리스 범위 확인. 이번 제출 금지 유지 |

### 사용자 조작만 필요한 항목

1. Play Console에서 com.onaria.app 선택 후 앱 무결성의 **업로드 인증서/앱 서명 인증서 공개 SHA1·SHA256**을 확인한다. 개인키나 비밀번호는 보내지 않는다.
2. 내부 테스트7의 앱 번들 탐색기에서 현재 artifact/권한·SDK 목록과 다른 트랙 최고 versionCode를 확인한다. 제공 가능한 비밀값 없는 자료만 대조한다.
3. provider 개발자 콘솔에서 Play 앱 서명에 대한 Google Android OAuth와 Kakao 키 해시·테스트 사용자/검수 상태를 확인한다. 외부 계정 인증은 사용자가 직접 한다.
4. 전용 심사 접근 방법·공개 연락처·국가·타겟18+·건강 기능 범위를 확인한다. 아직 모르는 답을 대신 제출하지 않는다.
5. 현재 권한 범위에서는 문서 검토만 한다. 기기 설치·운영 수정·스토어 제출/배포는 별도 요청 전 실행하지 않는다.

### 콘솔 연결 환경 점검

실행 중인 Chrome/Safari의 Play Console 탭 존재 여부만 읽었고 **발견 없음**이었다. Codex Document Control의 연결 세션도0개였다. 다른 탭 주소·계정·쿠키를 출력하거나 읽어 저장하지 않았다. 새 계정 인증·유료 브라우저 프로필 생성·세션 복제·우회는 하지 않았다. 따라서 콘솔 답변 저장/최종 제출은 **NOT RUN**이다.

## 9. 검증 결과와 보존 확인

- 현재 소스 대조: Build24 manifest165파일 SHA 일치, 누락0.
- AAB 읽기: package/versionCode21/versionName1.0.0/SDK24·36/권한 확인. 최초 protobuf 표시 스크립트의 타입 처리 오류를 수정해 재실행한 결과이며 최신24가 아니라는 사실은 유지.
- 로컬 AAB 공개 인증서 읽기 및 SHA256 파일 식별 완료. Play 인증서 일치는 미확인.
- 공개 정책·지원·삭제·약관4경로 HTTPS GET200, TLS 검증 유지. API health200과 assetlinks200/빈목록은 별도 기록.
- 관련 회귀: `node --test test/onaria_web.test.js test/privacy_security.test.js test/account_deletion.test.js test/ai_consent.test.js test/retention_maintenance.test.js` → **30 PASS, 실패/skip0, 종료0**. 임시 DB·로컬 HTTP만 사용.
- 이번 변경은 문서1개이므로 Flutter전체/analyze/native 재빌드/전체CI/브라우저화면/실기기·운영 삭제 시험은 **NOT RUN**. 과거 Build24 519backend/196Flutter 등의 수치는 이번 실행 결과가 아니다.
- 최종 문서 항목11개·경로·diff·비밀값 패턴 검사 PASS, 기존 ONARIA_ROADMAP.md 해시 보존 확인. 짧은 설명은41자로80자 이내다. 키·토큰·비밀번호·전체환경파일은 저장하지 않음.
- 운영 변경·서비스 재시작·기기 설치·실제 소셜 인증/철회·회원삭제·스토어 입력/제출·배포·병합·리베이스·커밋·푸시는 모두 **NOT RUN — 사용자 지정 보류**.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 75579eddaa83803a6d36ad026bf6e0476470b37a
ISSUE FOUND: 최신 소스24 대비 AAB21; Play 인증서·SDK 고지·심사 접근·등록 자산 미확인
PRIORITY: P1 인증/배포·개인정보
ROOT CAUSE: 과거 산출물·Apple 고지·직접 설치 검증은 Play 배포 증거와 범위가 다름
IMPLEMENTED: 11항목 입력 초안·근거·미확인·다음 단계 통합 문서; 앱/서버 소스 수정 없음
CHANGED FILES: docs/releases/ONARIA_GOOGLE_PLAY_READINESS_2026-10-19.md
TEST: 관련 로컬 회귀30 PASS; 공개URL4개200; source manifest165파일 일치
BUILD: NOT RUN — 기존 APK24/AAB21 읽기 검사만
DEVICE: NOT RUN — 설치·조작 없음
API: 공개 GET만; 외부AI·회원 API·운영 설정/DB NOT RUN
CI: NOT RUN — 문서 준비 작업
COMMIT: NOT RUN — 사용자 보류
PUSH: NOT RUN — 사용자 보류
REMAINING RISKS: 최종 AAB/Play7 차이, 앱서명 provider 등록, Android SDK/공유·건강 고지, 심사 접근, 이미지·삭제 요청·AI 신고
NEXT ACTION: 사용자의 공개 인증서·Play7/최고빌드 자료 확인 후 최종 AAB 재현과 고지·심사 접근 검증 준비
```


## 10. 최신 Release AAB 생성·검증 — 2026-10-19 후속 실행

사용자 요청에 따라 실제 빌드했다. 이번 섹션은 앞선 ‘최신 AAB 부재’를 해소하며, 앞선 회귀30 PASS는 이전 문서 준비 시점의 별도 결과로 유지한다.

### 사전점검·보존
- ONARIA main / HEAD `75579eddaa83803a6d36ad026bf6e0476470b37a`, pubspec **1.0.0+24** 재확인. 버전 번호·앱 ID 변경 없음.
- AGENTS.md, ARI_COMPLIANCE_STANDARD, ANDROID_RELEASE_UPDATE, 기존 installer/config helper와 Gradle 설정을 읽었다. 설치 스크립트는 기기 설치까지 이어지므로 실행하지 않고 빌드 명령만 재사용했다. 구형 build20 helper도 사용하지 않았다.
- AGENTS의 구형 soul-bible-release.jks 파일명은 현재 실제 키 경로와 다르다. 기존 key.properties의 secure 업로드 키가 존재하고 인증서 SHA1이 사용자 지정값과 일치함을 **빌드 전에** 확인했다. 키 교체·생성·복사·인증서 설정 변경 없음. 과거 ANDROID_RELEASE_UPDATE의 SHA256 `692e…`는 현재 key/cert 증거로 사용하지 않는다.
- 기존 AAB21을 exclusive copy로 별도 보존하고 SHA256 일치를 확인한 후 빌드했다. 기존 추적 소스 파일과 보호 설정/서명키의 해시를 전후 비교해 변경0을 확인했다. 기존 roadmap dirty 수정도 보존했다.
- 기존 `.onaria.local.env`는 dotenv 형식으로 Kakao native 설정이 있고, 무시된 Naver/Kakao·signing properties를 그대로 사용했다. 값과 비밀번호는 출력하지 않았다. 보호 파일의 기존 권한은 변경하지 않았다.

### 재현한 빌드 명령

```sh
flutter build appbundle --release \
  --dart-define-from-file=.onaria.local.env \
  --dart-define=ONARIA_API_BASE_URL=https://api.onaria.ai.kr
```

종료0. `--build-number`/`--build-name` override 없음. 기존 Release 서명 설정 사용. APK/AAB21의 버전만 수동 수정하거나 기존 바이너리를 재서명하지 않았다. 상세 도구 로그는 로컬 mode600 파일에 보관했다.

### 산출물 경로와 해시

빌드별 보존 디렉터리: `build/play-release/20261019-154539/` (Git 제외 build 경로).

| 파일 | 용도 | bytes / SHA256 |
|---|---|---|
| `build/app/outputs/bundle/release/app-release.aab` | 현재 기본 AAB24 출력 | 62,020,704 / `aa92b35ed470166be87a9c6ff1f51785f83b9dfa6da0bd2bf9167e0e3792494a` |
| `build/play-release/20261019-154539/onaria-1.0.0-build24-release.aab` | 이번 검증본 별도 보존 | 62,020,704 / `aa92b35ed470166be87a9c6ff1f51785f83b9dfa6da0bd2bf9167e0e3792494a` |
| `build/play-release/20261019-154539/preserved-onaria-1.0.0-build21.aab` | 기존 AAB21 원본 보존 | 61,723,264 / `98c0594eeae6775c13e6bfb6aa9d361c11efb8d27df62b20f3750c009683f886` |

`release-manifest.json`에 버전·HEAD·파일별 해시·검증 결과, `artifact-audit.json`에 AAB 실제 속성, `native-elf-alignment.json`에 라이브러리별 LOAD/RELRO 계산, `bundle-config.json`에 공식 도구의 config dump를 기록했다. 검증용 `.apks` 및 universal APK도 같은 폴더에 있으나 배포·설치용으로 사용하지 않았다.

### 검사 결과

| 검사 | 이번 결과 | 근거·실행 한계 |
|---|---|---|
| AAB 구조 | **PASS** | Google 공식 bundletool1.18.3 `validate` 종료0 |
| 패키지 | **PASS** | AAB manifest `com.onaria.app` |
| 버전 | **PASS** | AAB manifest versionName1.0.0 / versionCode24; pubspec 동일 |
| 빌드 종류 | **PASS** | Release; debuggable 속성 없음(Android 기본 false), extractNativeLibs=false |
| 서명 무결성 | **PASS** | jarsigner verify 종료0, jar verified. self-signed/인증기관 신뢰 체인·timestamp 경고는 일반 공개 CA 문서서명 기준 경고이며 요청된 인증서 대조와 구분 |
| 업로드 인증서 SHA1 | **PASS** | `6F:F3:39:0B:79:7B:24:DB:9D:2C:8A:79:B1:62:77:55:D7:0D:19:F7` 정확히 일치. 빌드 전 기존 키·빌드 후 AAB 모두 대조 |
| 인증서 SHA256 | **PASS** | `97:2A:E4:64:5E:3C:7C:93:FC:4D:38:58:25:0D:E1:A3:AF:93:C5:14:38:6C:5D:65:40:EF:D5:16:52:CD:3D:07` |
| SDK API | **PASS — 값 확인** | 실제 AAB min24 / target36 / compile36 |
| ABI | **PASS — 목록 확인** | arm64-v8a / armeabi-v7a / x86_64, 총12개 .so |
| 권한 | **PASS — 목록 대조** | 아래12개. 위치/연락처/SMS·통화/AD_ID/Billing/Health Connect 없음. 권한별 개인정보 최종 고지는 기존 Gate 유지 |
| 기기 백업 | **확인 필요 유지** | allowBackup 미명시(Android 기본 true). 계정별 SharedPreferences 기록의 OS 백업·복원/제외 규칙은 별도 검증 대상. 서버 탈퇴만으로 모든 OS 백업에서 즉시 사라진다고 고지하지 않음 |
| AAB 16KB 패키징 | **PASS** | `uncompressNativeLibraries.enabled=true`, `alignment=PAGE_ALIGNMENT_16K` |
| AAB 생성 APK ZIP16KB | **PASS** | 같은 AAB에서 bundletool universal APK 생성, 기존 키로 검증용 서명. build-tools36 zipalign `-v -c -P 16 4` 종료0 / Verification successful. apksigner verify도 종료0·기존 SHA256 일치 |
| 64비트 ELF PT_LOAD | **PASS — 정적** | arm64/x86_64의8개 .so 모두 p_align≥16384, offset/vaddr16KB congruence 확인. 나머지32비트4개도 별도 기록 |
| 64비트 RELRO 보호 레이아웃 | **PASS — 정적 계산 범위** | raw end modulo 검사와 전체 LOAD 보호 범위 검토를 구분. 아래 설명 참조 |
| 16KB 실제 실행 | **NOT RUN** | 기기 설치·에뮬레이터 실행 없음. 정적 검사를 runtime PASS로 확대하지 않음 |
| Play 앱 서명·설치 인증 | **BLOCKED** | 요청된 업로드 지문은 일치하지만 Play 최종 앱 서명 인증서/Google·Kakao 등록·Play 설치본 소셜 로그인은 별도 |

실제 AAB 권한:
`RECORD_AUDIO`, `INTERNET`, `RECEIVE_BOOT_COMPLETED`, `BLUETOOTH(max30)`, `BLUETOOTH_ADMIN(max30)`, `BLUETOOTH_CONNECT`, `VIBRATE`, `POST_NOTIFICATIONS`, `ACCESS_NETWORK_STATE`, `USE_BIOMETRIC`, `USE_FINGERPRINT`, `com.onaria.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.

### 16KB 검사 상세와 남은 한계

- 기준: [Android 공식 16KB 대응 안내](https://developer.android.com/guide/practices/page-sizes). APK ZIP 정렬과 ELF LOAD 정렬은 다른 검사이며 AAB 컨테이너 자체의 ZIP offset을 APK 기준으로 판정하지 않았다.
- 공식 Google bundletool1.18.3 standalone JAR를 GitHub google/bundletool 배포에서 받아 공식 release asset digest와 SHA256을 대조했다: `a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29`. 시스템 설치·기존 도구 교체 없음. 로컬 Gradle용 jar는 standalone entry가 없어 해당 용도로 사용하지 않았다.
- libapp/libflutter LOAD p_align은65536, libdartjni/libdatastore_shared_counter는16384이며 모든64비트 LOAD를 검사했다.
- 초기 단순 `(RELRO.vaddr+memsz)%16384==0` 검사에서 arm64 libflutter와 arm64/x86_64 libdatastore_shared_counter의3개가 미정렬로 나왔다. 즉시 제품 결함으로 확정하지 않고 NDK llvm-readelf와 전체 PT_LOAD 범위를 재검토했다.
- 이3개 RELRO는 대응 RW LOAD의 끝까지 보호하는 레이아웃이며,16KB로 확대한 보호 페이지 안에 **RELRO 밖의 실제 writable LOAD 바이트가 들어가는 충돌은0**이었다. 따라서 raw 끝주소가 나머지를 갖는다는 이유만으로 ‘RELRO is not a suffix’라고 단정하지 않는다. Android linker의 LOAD/RELRO 범위·확장 로직을 함께 참고했다: [AOSP linker_phdr.cpp](https://android.googlesource.com/platform/bionic/+/android16-qpr2-release/linker/linker_phdr.cpp), [RELRO 위치 판정](https://android.googlesource.com/platform/bionic/+/android16-qpr2-release/linker/linker_phdr_16kib_compat.cpp).
- **위 판단은 정적 레이아웃 검토다.** 원문 헤더와 계산을 JSON으로 남겼으며 Play Analyzer 실제 판정,16KB 환경에서 로딩·보안저장소·로그인·기록·알림 실행은 미검증이다. 필요하다면 다음 단계에서 동일 AAB와16KB 전용 테스트 환경으로 확인한다. 구간 헤더 패치/바이너리 alignment 강제값/압축 우회/SDK 다운그레이드는 하지 않았다.
- 검증용 APK 생성 첫 시도는 bundletool이 `env:` password 문법을 지원하지 않아 실패했다. 도구가 지원하는 `file:/dev/fd/...` 익명 파이프로 기존 비밀번호를 전달하여 재실행 종료0. 실제 값을 CLI·로그·임시 password 파일에 쓰지 않았다. 실패 시 debug키 fallback을 사용하지 않았다.

### SDK·도구 의존성 및 경고

- AGP9.1.0 / Gradle9.3.1 / Android NDK28.2.13676358 / Build-Tools36.0.0 설정·도구 확인.
- 방금 빌드한 releaseRuntimeClasspath를 `./gradlew --offline :app:dependencies --configuration releaseRuntimeClasspath`로 조회, 종료0. Google play-services-auth **21.6.0**, Naver Nid OAuth **5.11.2**, AndroidX DataStore **1.1.7**, security-crypto **1.1.0-alpha06** 확인. 전체 로그와 선택 목록은 빌드 폴더에 보관했다.
- Flutter의 Kakao·Google·Apple·Speech·local notification 등 버전은 기존 pubspec.lock을 그대로 사용했다. 이 목록은 SDK 데이터 수집/국외 처리의 무해성 인증이 아니다. Android SDK별 Data safety 확인은 남는다.
- 일부 기존 플러그인의 Built-in Kotlin 전환 경고가 남았지만 이번 빌드 실패는 없다. SDK·Flutter·Gradle·서명 설정을 임의 업그레이드하지 않았다.

### 이번 검증 범위와 최종 상태

- 최신 AAB 생성·패키지·버전·요청 인증서·무결성·권한·API SDK·16KB 패키징/ELF 정적 검사 **PASS(명시한 범위)**.
- 기존 추적 소스/사용자 수정/보호 설정/키 해시 변경0, 기존21 사본 해시 일치. 버전24 유지. 문서·ignored build 산출물 외 수정 없음.
- 이번에는 소스 기능 수정이 없어 Flutter전체/analyze/backend 회귀를 반복하지 않았다. 최초 문서 준비의 관련30 PASS는 별도 이력이다. 이번 결과는 실제 Release 빌드와 산출물 검증이다.
- **남은 문제:**16KB runtime·Play 최종 앱 서명/provider 등록·Play7 상세 diff·Data safety/건강/심사 접근/이미지/고지 Gate. 정적 AAB 통과만으로 비공개 테스트 시작/출시 Gate를 PASS라고 하지 않는다.
- **NOT RUN:** 기기 설치·데이터 조작·실제 소셜 인증/철회/회원삭제·스토어 업로드/제출·배포·운영 변경/재시작·병합/리베이스·커밋·푸시.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 75579eddaa83803a6d36ad026bf6e0476470b37a
ISSUE FOUND: 기존 AAB21은 소스24와 달랐음; 최신 AAB24 재생성 완료
PRIORITY: P1 서명/빌드
ROOT CAUSE: 이전 산출물 잔존, 최신24 AAB 미생성
IMPLEMENTED: 기존21 보존 후 공식 API·기존 보호 설정/키로24 AAB 생성 및 정적 검증
CHANGED FILES: 본 문서 및 Git 제외 build/play-release 산출물; 소스/버전 변경 없음
TEST: bundletool validate·JAR 서명·인증서·manifest·zipalign·ELF/RELRO 정적 검사 PASS
BUILD: Release AAB 1.0.0+24 PASS
DEVICE: NOT RUN — 설치·16KB 실행 없음
API: NOT RUN — 이번 빌드/검사 중 운영 API 호출 없음
CI: NOT RUN — 로컬 산출물 검증
COMMIT: NOT RUN — 사용자 보류
PUSH: NOT RUN — 사용자 보류
REMAINING RISKS: 16KB runtime, Play 앱서명/provider 등록, 등록 정보·심사·개인정보 Gate
NEXT ACTION: 사용자 Play 앱서명 인증서 대조 및 승인된 테스트 환경에서16KB/Play 설치본 검증
```


## 11. Play 비공개 테스트 준비 및 데이터 보안 초안 — 2026-10-22

- Alpha 트랙에 대한민국, 기존 ONARIA Internal Testers(8)와 tester(40) 목록을 연결하고, 기존 Play 라이브러리의 versionCode24/versionName1.0.0 및 한국어 테스트 출시 노트를 저장했다. 목록 간 중복 및 실제 참여자 수는 미검증이다.
- 빈 AAB 초안으로 발생한 출시 검토 오류2개를 해소했다. 광고 ID 미사용 선언도 저장했다. Build24 AAB manifest의 AD_ID 및 ACCESS_ADSERVICES_AD_ID 권한 부재를 재확인했다.
- 게시 개요의 제출 차단 문제는 불완전한 데이터 보안 선언1개였다. 심사 전송 및 테스트 시작은 미실행이다.
- 데이터 보안: 기존 사용자ID(수집/비공유/비임시/선택/앱기능·계정관리)를 유지했다. 기타 인앱 메시지와 건강정보는 수집/비공유/임시처리 예외 미적용/핵심 대화 기능에 필요한 수집/앱기능으로 각각 저장하고 전체 양식을 임시저장했다. 이는 선택한3유형의 문항 완성이며 전체 수집범위 적합 판정이 아니다.
- 최초 메시지의 임시처리·선택수집 저장은 자동 검토에서 근거 부족으로 거절됐다. 해당 입력을 취소하고 소스 및 운영 프록시를 추가 점검한 뒤 수정된 답변을 저장했다.
- 운영 설정 파일에서 SOUL_AI_MODE=local, SOUL_MULTI_AGENT_ENABLED=false, SOUL_EXTERNAL_API_DISABLED=true만 선별 조회했다. 전체 환경파일·키·토큰·회원 데이터는 출력하지 않았다. 설정 파일 확인을 모든 런타임 경로 검증으로 확대하지 않는다.
- 운영 nginx 설정에서 요청 본문 로그 참조는 발견하지 못했고 ONARIA 전용 최소 접속 로그가 설정돼 있다. client_body_buffer_size/proxy_request_buffering 별도 설정은 조회 결과 없었다. Nginx 기본값상 큰 요청은 디스크 임시 파일을 거칠 수 있으므로 메모리 전용 임시처리 예외를 주장하지 않았다. 실제 사용자 요청의 임시 파일 생성·내용은 열람하지 않았다.
- 앱 소스의 전송 동의 거절/실패 시 반환, 전송 직전 허용 재확인, 앱 기능 목적을 대조했다. 현재 소스와 과거 Build24 재현 소스의 상세 차이는 별도 최종 검토 대상이다.
- 내부 테스트는 Data safety 면제 대상이다. 내부 테스트 성공을 데이터 보안 양식 승인/검증으로 간주하지 않는다.
- 최종 제출 전 남은 대조: 로그인 제공자 동의항목/SDK 자동수집과 이름·이메일·전화·종교정보의 실제 전송 범위, OS 음성 처리, 접속·사용량·진단 정보의 유형/목적/선택성, 전송 보안 전체 범위, 심사 접근 안내. 기존 '모든 기능에 접근 제한 없음' 선언은 로그인 필요 계정 기능과 정합성 확인 필요.
- 운영 변경·서비스 재시작·기기 설치·로그인/탈퇴 조작·외부 AI 호출·커밋·푸시 없음.
- 근거: Google Data safety https://support.google.com/googleplay/android-developer/answer/10787469 ; Nginx client_body_buffer_size https://nginx.org/en/docs/http/ngx_http_core_module.html#client_body_buffer_size
