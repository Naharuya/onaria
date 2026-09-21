# ONARIA MVP Store Submission Checklist

기준일: 2026-09-21

이 문서는 ONARIA MVP를 Google Play와 Apple App Store에 등록하기 위한 실행 체크리스트다.
운영 서버 변경과 스토어 심사 제출은 최종 Preflight 및 사용자 승인 후 진행한다.

## 1. 현재 확정된 앱 정보

- 앱 이름: ONARIA
- Android applicationId: `com.onaria.app`
- iOS bundle ID: `com.onaria.app`
- 현재 앱 버전: `0.4.1+6`
- Production API: `https://api.onaria.ai.kr`
- Website: `https://onaria.ai.kr`
- Privacy URL: `https://onaria.ai.kr/privacy`
- Terms URL: `https://onaria.ai.kr/terms`
- Android target/compile SDK: API 36
- iOS build environment baseline: Xcode 26+ / iOS 26 SDK+

## 2. Google Play 준비

### 앱 생성
- [ ] Play Console에서 새 앱 생성
- [ ] 기본 언어: 한국어
- [ ] 앱 이름: ONARIA
- [ ] 앱/게임: 앱
- [ ] 무료/유료 정책 확정
- [ ] 개발자 연락처 입력

### 빌드
- [x] applicationId = `com.onaria.app`
- [x] targetSdk = 36
- [x] compileSdk = 36
- [ ] 신규 upload keystore 생성 또는 기존 정식 키 복원 정책 확정
- [ ] Release AAB 생성
- [ ] AAB non-debuggable 확인
- [ ] Production API 포함 확인
- [ ] Play App Signing 등록
- [ ] versionCode 중복 여부 확인

### Store listing
- [ ] 앱 아이콘 512x512
- [ ] Feature graphic 1024x500
- [ ] 휴대폰 스크린샷
- [ ] 앱 짧은 설명
- [ ] 앱 전체 설명
- [ ] 앱 카테고리
- [ ] 연락 이메일
- [ ] 개인정보처리방침 URL

### App content
- [ ] Data safety
- [ ] 연령 등급
- [ ] 광고 여부
- [ ] 앱 액세스/로그인 필요 여부
- [ ] 건강/의료 관련 표현 점검
- [ ] 타겟 사용자/콘텐츠
- [ ] 뉴스/정부/금융 등 특수 카테고리 해당 없음 확인

## 3. Apple App Store 준비

### Apple Developer / App Store Connect
- [ ] Apple Developer에서 `com.onaria.app` App ID 등록
- [ ] Associated Domains entitlement 확인
- [ ] App Store Connect 새 앱 레코드 생성
- [ ] 플랫폼: iOS
- [ ] 앱 이름: ONARIA
- [ ] 기본 언어: 한국어
- [ ] Bundle ID: `com.onaria.app`
- [ ] SKU 결정

### Signing / Build
- [x] Bundle ID 코드 반영
- [ ] Apple Developer Team 연결
- [ ] Distribution certificate / provisioning profile
- [ ] Release archive
- [ ] TestFlight upload
- [ ] 실제 앱 버전/빌드번호 확인

### App Store metadata
- [ ] Subtitle
- [ ] Promotional text
- [ ] Description
- [ ] Keywords
- [ ] Support URL
- [ ] Marketing URL
- [ ] Privacy Policy URL
- [ ] iPhone screenshots
- [ ] iPad 지원 여부에 따른 screenshots
- [ ] App Privacy
- [ ] Age Rating 최신 질문
- [ ] Review notes
- [ ] Demo/login account 필요 여부

## 4. 현재 권한 및 개인정보 관련 사실

### Android 권한
- RECORD_AUDIO
- INTERNET
- RECEIVE_BOOT_COMPLETED
- BLUETOOTH / BLUETOOTH_ADMIN (Android 11 이하 범위)
- BLUETOOTH_CONNECT

### iOS 권한 설명
- Microphone: 마음 이야기를 음성으로 입력
- Speech Recognition: 음성을 글자로 변환

### 현재 데이터 경로
- 마음대화 입력/최근 대화 맥락: 서버 전송
- 외부 AI 활성 시 필요한 대화 맥락: AI 제공자 전달 가능
- 회원가입: 이름, 휴대폰 번호, 선택 교회명
- 마음카드: 일부 기기 로컬 저장
- 감정카드 사용 빈도/키워드: 현재 기기 로컬
- AI 사용량: 토큰/비용 추정/가명 식별자 가능
- Safety Admin: 위험 분류/시간/집계 중심, 원문 기본 비표시

## 5. Data Safety / App Privacy 초안

아래는 코드 기준 초안이며 Play Console/App Store Connect 제출 전 실제 운영 설정과 일치 여부를 최종 확인한다.

### 수집 가능 데이터
- 사용자 제공 텍스트 대화
- 음성 입력은 STT 처리 후 텍스트로 사용
- 회원가입 시 이름/전화번호/교회명
- AI usage metadata
- 안전 분류 metadata

### 사용 목적
- 앱 기능 제공
- AI 대화/성찰 생성
- 계정/회원 관리
- Safety 운영
- 비용/서비스 운영

### 확인이 필요한 항목
- [ ] 외부 AI 제공자에게 전송되는 정확한 데이터 항목
- [ ] 국외 이전 국가/법인/보유기간
- [ ] 회원 DB 보유기간
- [ ] 탈퇴/삭제 요청 처리
- [ ] analytics가 실제 production에서 켜지는지
- [ ] crash reporting/analytics SDK 존재 여부
- [ ] 데이터 암호화/전송 HTTPS 확인
- [ ] 계정 삭제 기능 제공 방식

## 6. 법적 문서 출시 전 확정 필요

현재 /privacy와 /terms는 사전 안내 성격이므로 아래 실제 사업자 정보를 확정해야 한다.

- [ ] 운영주체/상호
- [ ] 대표자명
- [ ] 사업자등록번호 (해당 시)
- [ ] 주소
- [ ] 개인정보 보호 문의 이메일
- [ ] 고객지원 이메일
- [ ] 개인정보 보유기간
- [ ] 회원 탈퇴/삭제 절차
- [ ] 외부 AI 제공자 및 국외이전 내용
- [ ] 만 14세 미만 이용 정책
- [ ] 분쟁/준거법/서비스 중단 안내

## 7. 스토어 설명 초안

### 짧은 설명
마음을 안전하게 돌아보고, AI 대화와 성경 말씀, 작은 실천으로 하루를 정리하는 마음관리 앱.

### 전체 설명
ONARIA는 지금의 감정을 선택하고 AI와 짧게 대화하며 마음을 돌아본 뒤, 관련된 성경 말씀과 오늘 할 수 있는 작은 실천으로 연결하는 신앙 기반 마음관리 앱입니다.

주요 기능:
- 감정 체크인과 강도 기록
- 안전을 우선하는 AI 마음대화
- 성경 말씀과 묵상 질문
- 오늘의 작은 실천
- 마음카드 저장과 공유
- 7일 마음의 여정
- 알림과 성장 기록
- 빛 조각으로 십자가를 완성하는 미니게임

ONARIA는 의료 진단, 치료, 전문 상담 또는 종교기관의 공식 자문을 대신하지 않습니다. 위기 상황에서는 앱의 답변보다 현실의 긴급 지원과 주변 사람의 도움을 우선합니다.

## 8. 스크린샷 권장 순서

1. 홈 / 감정 체크인
2. AI 마음대화
3. 말씀 연결
4. 작은 실천
5. 마음카드
6. 7일 마음의 여정
7. 십자가 미니게임
8. Safety/신뢰 안내

스크린샷에는 실제 사용자 개인정보나 실제 상담 원문을 사용하지 않는다.

## 9. 제출 전 최종 기술 Gate

- [ ] `flutter pub get`
- [ ] `flutter test`
- [ ] `flutter analyze lib test example --no-fatal-infos`
- [ ] Android debug build
- [ ] Android release AAB
- [ ] iOS simulator compile
- [ ] iOS archive/TestFlight build
- [ ] backend tests
- [ ] Website/Admin E2E
- [ ] production /health
- [ ] normal AI roundtrip
- [ ] crisis provider-call delta 0
- [ ] 개인정보/약관 실제 운영정보 일치
- [ ] secret scan
- [ ] 최종 commit SHA 고정

## 10. 사람의 입력이 반드시 필요한 항목

다음 값은 코드에서 추측하거나 자동 생성하지 않는다.

- Google Play 개발자 계정 정보
- Apple Developer Team/Account 정보
- 사업자/운영주체 법적 정보
- 고객지원/개인정보 문의 이메일
- 최종 무료/유료 정책
- Apple SKU
- 스토어 공개 국가/지역
- 만 14세 미만 이용 정책
- 실제 외부 AI 제공/국외이전 정보

이 값들이 확정되면 /privacy, /terms, Play Data Safety, Apple App Privacy를 같은 기준으로 맞춘다.
