# ONARIA Final UI/UX Layout Review

기준일: 2026-09-22

## 목적
스토어 등록 전 사용자 앱, Website, Admin에서 다음 문제를 재점검한다.

- 긴 제목/버튼/메뉴가 의도치 않게 두 줄로 내려가는 문제
- Row 내부 텍스트가 좁은 화면에서 overflow 되는 문제
- 태블릿/넓은 화면에서 콘텐츠가 한쪽으로 붙거나 지나치게 넓어지는 문제
- 360~430px 휴대폰에서 터치/읽기 흐름이 깨지는 문제
- 본문과 UI 라벨의 줄바꿈 규칙이 섞이는 문제

## 공통 UI 규칙

### 한 줄을 유지하는 항목
- 메뉴 항목
- 카드 라벨
- 상태 라벨
- 짧은 버튼 라벨
- 감정 카드 이름
- 헤더 옆 보조 상태

이 항목은 `maxLines: 1` + ellipsis/Flexible/Expanded를 사용한다.

### 자연스러운 줄바꿈을 허용하는 항목
- 설명 본문
- AI 답변
- 말씀 본문
- 묵상 질문
- 법적/안전 안내
- 사용자가 입력한 긴 기록
- 긴 답변 예시

이 항목은 가독성을 위해 억지로 한 줄로 축소하지 않는다.

## 앱 검토 결과

### 감정 체크인
확인:
- 화면 본문 최대 폭 620px
- “지금 가장 가까운 마음을 골라주세요”와 “선택됨”이 같은 Row에서 충돌 가능
- 동적 감정카드 이름이 두 줄로 내려갈 가능성

조치:
- 제목 영역을 Expanded 처리
- 선택 상태와 간격 분리
- 감정카드 라벨을 한 줄 + ellipsis로 고정

### 회원가입
확인:
- “Google 로그인 (준비 중)” 등 소셜 버튼이 360px 또는 글자 확대에서 overflow 가능

조치:
- 버튼 텍스트 Flexible
- 한 줄 + ellipsis
- 아이콘/텍스트 중앙 정렬 유지

### 소셜 제공자 설정
확인:
- provider 이름이 Row에서 확장 영역 없이 배치됨

조치:
- provider 텍스트 Expanded + 한 줄 ellipsis

### AI 마음대화
확인:
- 메인 콘텐츠 최대 폭 720px로 제한되어 있음
- 음성 인식 상태 문구가 좁은 화면에서 Row overflow 가능
- 답변 예시는 긴 문장이므로 의도적 줄바꿈 허용

조치:
- 음성 상태 문구 Flexible + 한 줄 ellipsis
- 답변 예시는 축소하지 않고 읽기 우선 유지

### 작은 성장 기록
확인:
- 넓은 화면에서 ListView가 화면 전체 폭을 사용해 시선이 좌측으로 쏠릴 수 있음

조치:
- 중앙 정렬 + 최대 폭 620px

### 저장된 마음카드
확인:
- 넓은 화면에서 카드 폭이 과도하게 넓어질 수 있음

조치:
- 카드 목록 중앙 정렬 + 최대 폭 620px
- 날짜/에이전트명은 기존 Expanded 구조 유지

### 말씀과 작은 기록
확인:
- 태블릿에서 전체 폭 사용

조치:
- 중앙 정렬 + 최대 폭 620px
- 저장/공유 버튼은 Wrap을 유지해 작은 화면에서 안전하게 재배치

### 7일 마음의 여정
확인:
- 태블릿에서 본문이 지나치게 넓어질 수 있음
- 감정 ChoiceChip은 의도적 Wrap

조치:
- 중앙 정렬 + 최대 폭 620px
- ChoiceChip은 자연스러운 행바꿈 유지

### 알림 설정
확인:
- 넓은 화면에서 설정 목록이 좌측으로 퍼져 보일 수 있음

조치:
- 중앙 정렬 + 최대 폭 620px

### 공유 미리보기
확인:
- 페이지 설명/버튼 영역이 태블릿 전체 폭을 사용

조치:
- 전체 콘텐츠 최대 폭 620px
- 이미지 자체는 최대 폭 380px 유지

### 십자가 빛 모으기
확인:
- AppBar 제목 “빛 조각으로 십자가 완성하기”가 작은 화면에서 길음

조치:
- “십자가 빛 모으기”로 단축
- 본문 620px 중앙 정렬 유지
- 365 사유/말씀은 본문이므로 자연스러운 줄바꿈 유지

## Website / Admin

기존 Playwright E2E는 Website를 360 / 390 / 430 / 768 / 1024 / 1280 / 1440px에서 가로 overflow와 접근성을 검사한다.

추가 조치:
- Website visual checkpoint 범위를 360 / 390 / 430 / 768 / 1024 / 1440px로 확대
- Admin responsive route 검사에 `/admin/privacy` 추가
- Admin은 360 / 390 / 430 / 768 / 1280px에서 가로 overflow 검사 유지

## 새 Flutter 회귀 테스트

`test/responsive_layout_test.dart`
- 360px
- 390px
- 430px

대상:
- Check-in
- 회원가입

확인:
- 메뉴를 열었을 때 RenderFlex/layout exception 없음
- 회원가입 화면을 스크롤했을 때 overflow exception 없음

## 남은 검증

현재 GitHub Actions 환경은 workflow step 실행 전에 실패하는 runner 문제가 있어 새 UI 회귀 테스트의 CI PASS 증거는 아직 없다.

따라서 다음 REAL 검증이 필요하다.

1. Mac에서 `flutter test test/responsive_layout_test.dart`
2. `flutter analyze lib test example --no-fatal-infos`
3. 최신 debug APK 빌드
4. 360px급 Android 실기기에서 홈/회원가입/대화/여정/알림/공유/십자가 확인
5. 글자 크기 확대 상태에서 버튼/헤더/카드 라벨 확인
6. Playwright Website/Admin 회귀 실행

검증이 끝나기 전에는 CODE 수정과 TEST PASS를 같은 것으로 표시하지 않는다.
