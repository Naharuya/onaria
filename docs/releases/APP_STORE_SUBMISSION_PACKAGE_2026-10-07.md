# ONARIA App Store 제출 패키지

기준: 2026-10-07, Asia/Seoul. 이 문서는 로컬 입력 준비물이며 App Store Connect에 저장·업로드·제출한 기록이 아니다. 다른 프로젝트를 변경하지 않는다.

## 앱 정보 입력안

| 필드 | 준비값 |
|---|---|
| 앱명 | ONARIA |
| 한국어 부제 | 마음을 돌아보고 말씀과 연결하는 시간 |
| 기본 언어 | 한국어 |
| Bundle ID | com.onaria.app |
| SKU | 아직 콘솔 앱 레코드 미확인. 기존 SKU를 사용하며 중복 앱을 만들지 않는다. |
| 가격 | 무료. 현재 앱 내 구매·유료 구독·결제 기능 없음. |
| 기본 카테고리 | Lifestyle (라이프스타일) |
| 연령 정책 | 만 18세 이상 성인. 연령 설문 후 필요하면 더 높은 등급으로 조정. |
| 운영자 | 조세진 |
| 지원 이메일 | vjsjv7003@gmail.com |
| 지원 URL | https://onaria.ai.kr/account-deletion (문의 이메일 및 앱 이용·삭제 방법 포함) |
| 마케팅 URL | https://onaria.ai.kr/ |
| 개인정보 URL | https://onaria.ai.kr/privacy |
| 개인정보 선택 URL | https://onaria.ai.kr/account-deletion |
| 이용 안내 | https://onaria.ai.kr/terms |
| Copyright | 2026 조세진 |
| Version / Build | 최종 Archive의 CFBundleShortVersionString / CFBundleVersion을 사용. pubspec 기준 0.4.4+10은 기존 설치용 값이므로 업로드 중복 여부 확인 전 제출 번호로 확정하지 않음. |

### 프로모션 문구

오늘의 감정을 살펴보고 말씀과 작은 실천으로 하루를 돌아보세요. 만 18세 이상을 위한 무료 마음관리 서비스입니다.

### 설명

ONARIA는 지금의 감정을 돌아보고 성경 말씀과 작은 실천으로 하루를 정리하는 신앙 기반 마음관리 앱입니다. 만 18세 이상 성인을 대상으로 무료로 제공합니다.

주요 기능
- 오늘의 감정과 마음 강도 확인
- 마음대화와 묵상 질문
- 한국어 개역한글·영어 World English Bible 말씀 보기와 음성 듣기
- 오늘 할 수 있는 작은 실천
- 마음카드 저장과 공유
- 저장한 말씀과 7일 여정
- 기기에 저장한 기록 관리와 회원탈퇴

한국어 말씀은 대한성서공회의 개역한글 원문을, 영어 말씀은 eBible.org의 World English Bible 원문을 표시합니다.

마이크·음성인식은 음성 입력을 선택할 때 사용합니다. 텍스트로도 이용할 수 있습니다. 계정 기능에는 Apple 등 지원되는 소셜 로그인을 사용하며 이름·전화번호·교회명은 선택 입력입니다.

현재 운영 서버의 외부 AI 호출은 차단되어 있으며 마음대화는 로컬 규칙·검토된 콘텐츠 경로를 사용합니다. 외부 AI 기능을 활성화할 때에는 별도의 데이터 처리 안내와 허용 절차가 필요합니다. 생성형 AI 기능이 활성화되어 있다고 광고하지 않습니다.

ONARIA는 의료 진단·치료, 전문 심리상담 또는 종교기관의 공식 자문을 대신하지 않습니다. 긴급한 위험에는 현실의 긴급 지원과 주변 사람의 도움을 우선하세요.

개인정보 처리 안내: https://onaria.ai.kr/privacy
지원·삭제 안내: https://onaria.ai.kr/account-deletion
문의: vjsjv7003@gmail.com

### 키워드

`마음관리,성경,기도,묵상,감정,신앙,기독교,말씀,마음대화,성찰`

## App Privacy 입력 검토표

현재 자사 코드·운영 확인 기준이다. 최종 Archive에 포함된 네이버·카카오·Google 로그인 SDK의 실제 수집도 합쳐서 검토한다. 코드에 추적 기능이 없다는 사실만으로 모든 SDK의 Tracking 응답을 자동 확정하지 않는다.

| Apple 데이터 유형 | 현재 근거 | 입력 준비 |
|---|---|---|
| Name | 선택 이름을 회원 DB에 보관 | 수집 있음 / App Functionality / 계정 연결 있음 |
| Phone Number | 선택 전화번호를 회원 DB에 보관 | 수집 있음 / App Functionality / 계정 연결 있음 |
| User ID | 소셜 계정 식별자·회원 식별자·세션 | 수집 있음 / App Functionality / 계정 연결 있음 |
| Sensitive Info | 선택 교회명을 회원 DB에 보관, 종교 정보 | 수집 있음 / App Functionality / 계정 연결 있음 |
| Other Usage Data | 가명 AI 사용량·비용·보안 제한 원장 | 수집 있음 / App Functionality. 가명화만으로 Not Linked 확정 금지; 재연결 가능성 검토 |
| Performance Data / Other Diagnostic Data | 서버 지연·토큰 수·상태 등 운영 계측 | 실제 보관 항목 대조 후 해당 유형·App Functionality 선택 |
| Other User Content | 자유 입력 대화는 현재 요청 응답 이후 원문 저장하지 않는 코드 경로 | 일시 처리만이면 수집 정의에서 제외 가능. 운영 프록시·APM·외부 SDK 보관 여부 확인 전 최종 응답 미확정 |
| Audio Data | ONARIA 서버는 음성 파일 저장 안 함, 플랫폼 STT 사용 | 앱·제3자 SDK가 응답 이후 보관하는지 검토. Apple 자체 처리와 자사 수집을 구분 |
| Email Address | 현재 회원 DB에는 이메일 필드 없음 | 소셜 SDK·지원 요청의 수집 여부 검토 후 결정 |
| Gameplay Content | 십자가 미니게임 기록은 기기에만 보관 | 서버·SDK 전송이 없다면 제외 |
| Location / Contacts / Photos / Payment / Purchases | 현재 수집·결제 기능 확인되지 않음 | 최종 SDK·Archive 점검 뒤 없음 판단 |
| Tracking | 자사 광고 추적·IDFA 기능 미확인 | SDK 파트너의 광고 결합·브로커 공유까지 확인 후 없음 확정 |

Apple의 수집 기준은 기기 밖으로 전송해 요청 처리보다 오래 접근할 수 있도록 보관하는 경우를 포함한다. 선택 입력·허용 후 수집도 자동 제외되지 않으며, 기기에서만 처리하는 기록과 서버 기록을 구분한다. [App Privacy 공식 기준](https://developer.apple.com/app-store/app-privacy-details/)

## 만 18세 이상 연령 설문 준비

회원가입의 성인 확인은 자체 이용 조건이다. App Store 표시 등급을 변경한 기록은 없다. 설문을 실제 빌드에 맞게 답하고 계산 등급이 정책보다 낮으면 Override to Higher Age Rating으로 18세 이상 정책에 맞춘다. 국가별·OS별 표시값을 확인한다. [Apple 연령 설정](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/)

| 설문 범주 | 확인할 실제 기능 |
|---|---|
| 광고 | 현재 광고 기능 없음. 외부 로그인 SDK 동작 추가 확인 |
| 메시지·채팅 | 다른 사용자와 메시지 교환 기능 없음. 마음대화가 설문의 chatbot 또는 messaging 정의에 해당하는지 현재 문항 설명 확인 |
| 사용자 생성 콘텐츠 | 자유 문장·기기 카드 저장 있음, 공개 피드 없음. 문항이 공개 공유를 뜻하는지 정의 확인 |
| 무제한 웹 접근 | 외부 개인정보·약관·인증 링크는 존재. 일반 웹 브라우저 제공 여부와 구분 |
| 건강·웰니스 | 감정 성찰·마음관리 내용 있음. 의료·치료 기능 없음; wellness 문항은 실제 내용 기준 응답 |
| 폭력·자해·성적 내용·약물·공포 | 위기 안전 안내와 성경 선택 구절·자유 입력을 실제 검토. 단순히 18+를 원하는 이유로 빈도를 임의 부풀리지 않음 |
| 도박·경품·확률 구매 | 현재 없음 |
| 보호자·연령 보장 도구 | 만 18세 이상 자기 확인 체크 있음. 생년월일 검증·Apple Declared Age API·보호자 통제 구현으로 오인하여 답하지 않음 |

## 심사 메모 입력안 (English)

ONARIA is a free reflection and scripture app for adults aged 18 and above. It does not offer in-app purchases, subscriptions, medical diagnosis, or treatment.

The main flow is emotion check-in, a reflection conversation, selected scripture, a small action, and optional local record saving. The initial screen opens the basic flow without an account. Account-related features are available through supported social sign-in, including Sign in with Apple. Name, phone number, and church name are optional.

The production server currently disables external AI calls. Requests use local rules and curated-content paths. The app includes an explicit external-AI permission mechanism, but this is not a claim that the external provider is enabled.

Microphone and speech recognition permissions are requested for optional voice input. Text input remains available.

Account deletion is available from the home menu, 계정 관리 (Account Management), then 회원탈퇴 (Delete Account). An Apple-linked account requires Apple reauthentication and token revocation. Deletion of the member profile, linked identities, and ONARIA sessions was verified on an iPhone and the server. Device-only saved records can be managed separately on the same privacy screen.

Contact: vjsjv7003@gmail.com. Privacy policy: https://onaria.ai.kr/privacy

### 심사 접근 확인

- 최종 후보에서 비로그인 핵심 흐름이 열리는지 확인한 뒤 기본 흐름에 Sign-in Required를 불필요하게 설정하지 않는다.
- 계정·탈퇴 검증은 심사자의 Apple 계정으로 가능한 경로를 안내한다. 실제 사용자 계정 비밀번호·토큰을 심사 메모에 넣지 않는다.
- App Review 연락처의 전화번호·이름은 콘솔에서 실제 운영자 값 확인이 필요하다. 이번 문서에는 추정 전화번호를 만들지 않는다.
- 회원 생성·탈퇴는 심사 계정의 요청으로 수행한다. 운영 기존 회원을 테스트 대상으로 삭제하지 않는다.

## 스크린샷 촬영 준비

현재 프로젝트는 `TARGETED_DEVICE_FAMILY = 1,2`로 iPhone·iPad를 지원한다. Apple 현재 규격은 iPhone Dynamic Island 중간 크기와 iPad 지원 시 13인치 화면이 필요하다. 우선 PNG 세로 iPhone 1179×2556 또는 1206×2622, iPad 2064×2752 또는 2048×2732로 실제 앱을 촬영한다. 실제 렌더링 크기를 검사하고 기종 이름만으로 규격을 추정하지 않는다. [Apple 스크린샷 규격](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)

| 순서 | 실제 화면 | 캡션안 | 데이터 |
|---|---|---|---|
| 01 | 첫 화면·감정 체크인 | 오늘 마음은 어떤가요? | 테스트 화면, 실제 회원정보 없음 |
| 02 | 마음 강도·예시 질문 | 천천히 마음을 돌아보는 시간 | 합성 예시 |
| 03 | 로컬 마음대화 결과 | 지금 가능한 작은 한 걸음 | 합성 입력, 외부 유료 호출 없음 |
| 04 | 한국어·영어 말씀 | 원문과 함께 읽고 듣는 말씀 | 공식 출처 표시 포함 |
| 05 | 마음카드·기록 | 기기에 남기는 오늘의 기록 | 합성 카드 |
| 06 | 개인정보·기록 관리 | 내 기록을 직접 관리하세요 | 이메일·전화번호·소셜 식별자 없는 상태 |

사용자 계정·대화·토큰을 캡처하지 않는다. 회원가입 완료나 AI 클라우드 기능 등 실제 화면에 없는 기능을 그림으로 합성하지 않는다. 시뮬레이터 캡처는 실제 앱 렌더링이며 실기기 검증을 대신하지 않는다. 촬영 결과는 별도 build 산출물 폴더에 보관하며 기기 자료를 삭제하지 않는다.

기존 최신 실기기 Release 산출물의 PrivacyInfo 매니페스트 21개는 NSPrivacyTracking=false, tracking domains 0으로 파싱 확인되었다. 이는 매니페스트의 선언 근거이며 SDK 실제 동작의 완전한 무추적 증명은 아니다. 최종 배포 Archive에서도 다시 확인한다.

## 실제 촬영 결과

앱 후보 커밋 `1014debff487fdd11625ecccd9d4c47c025aeb5e`, simulator 0.4.4 (10), `com.onaria.app`의 첫 감정 체크인 화면을 촬영했다. 기존 9월 빌드를 재사용하지 않았다.

- iPhone 17: `build/app-store-submission/screenshots/iphone/01-check-in.png`, 1206×2622 PNG.
- iPad Pro 13-inch M5: `build/app-store-submission/screenshots/ipad/01-check-in.png`, 2064×2752 PNG.
- 두 파일을 직접 시각 검사했고 실제 회원정보와 화면 overflow는 보이지 않았다. 비로그인 첫 화면 진입을 확인했다. PNG 크기·SHA256은 `capture-plan.json`에 기록했다.
- 비교 보기: `build/app-store-submission/screenshots/index.html`.
- Apple 필수 기기별 첫 화면 1장씩 준비했으며 위 02–06 추가 기능 화면은 아직 촬영하지 않았다. 실제 App Store 업로드·심사 제출은 실행하지 않았다.

## 제출 전 실행 체크

1. 최종 앱 커밋과 Archive의 버전·빌드·bundle ID·배포 서명·entitlement·SDK 개인정보 보고서 확인.
2. iPhone·iPad 실제 레이아웃과 스크린샷 개인정보·규격 확인.
3. 공개 정책 URL과 후보 기능·운영 설정이 일치하는지 확인.
4. App Store Connect 로그인 후 기존 앱 레코드, 계약·사업자·지원 전화번호·수출 규정 상태 확인. 현재 Info.plist의 ITSAppUsesNonExemptEncryption은 미설정이므로 실제 암호화 사용을 검토하고 설문에 답한다. 임의로 false를 삽입하거나 수출 규정 면제 완료로 표시하지 않는다.
5. Archive 검증 및 TestFlight 업로드. 처리 완료 후 동일 빌드에서 핵심 흐름·로그인·탈퇴 확인.
6. App Privacy·연령 설문·무료 가격·스크린샷·메타데이터를 실제 콘솔에 저장.
7. 최종 심사 제출은 업로드 완료와 별개로 기록하며 자동 출시 대신 최초 검토 시 수동 출시 선택 여부를 확인.

## 증거와 남은 Gate

부모 작업의 확인 기록: 백엔드 PR 38 main 배포 및 iPhone 회원탈퇴 후 member / identity / session 0 검증 완료. 상세는 `GABIA_APPLE_DEPLOYMENT_2026-10-07.md`와 최신 작업 보고를 따른다. 이 문서가 추가 테스트나 운영 재삭제를 실행했다는 뜻은 아니다.

App Store Connect 로그인·실제 설정, 배포 Archive/업로드, 추가 기능 스크린샷, SDK 개인정보 수집 최종 검토, 운영 로그·백업 보유기간과 Apple 토큰 철회 운영 설정의 후보 일치는 확인 중이다. 완료되지 않은 항목을 제출 완료로 표시하지 않는다.
