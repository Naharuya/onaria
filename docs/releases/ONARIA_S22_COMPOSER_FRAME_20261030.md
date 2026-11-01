# S22 공포 아이콘·입력 프레임

PROJECT: ONARIA
CURRENT COMMIT: 40cd65851553238c426b32f5af2639e76f24f64b
ISSUE FOUND: 공포 아이콘이 어두운 배경에 보이지 않음. 입력창 프레임이 보내기·마이크까지 감싸도록 요청.
PRIORITY: P2 UI/UX
ROOT CAUSE: 공포 아이콘이 어두운 달(🌑). 기존 TextField만 독립 테두리 사용.
IMPLEMENTED: 공포 😨 아이콘. TextField 내부 선 제거. 입력·보내기·마이크를 하나의24dp 둥근 테두리 안에 배치. 기본선 .8dp/alpha.18, 이동선1.2dp/alpha.75. 길이53dp, 주기10초. foreground CustomPainter와 자식 RepaintBoundary로 입력 내용 재빌드 방지. 화면 밖 TickerMode·백그라운드·모션 감소·비활성 입력에서 반복 정지.
CHANGED FILES: lib/app/quiet_composer_frame.dart, lib/features/conversation_page.dart, lib/features/check_in_page.dart, pubspec.yaml, test/quiet_composer_frame_test.dart. 대화 로직 테스트6파일은 반복 장식 모션을 끄는 명시적 fixture 인자 추가.
TEST: 대화·위기·예시5개·말씀/실천 연결11 PASS /1 SKIP. 테두리360/390/430px 배치·모션 감소·백그라운드 정지·재개3 PASS. 정적 분석 오류0 경고0 정보2.
BUILD: Release APK 1.0.0+28 빌드 성공 후 기존 updateRelease 검증 경로로 S22 adb install -r 및 앱 실행 확인. VERIFIED_BUILD 28.
DEVICE: Galaxy S22 Ultra SM-S908N R3CT10BVG6V만 지정
API: 변경 없음
CI: NOT RUN
COMMIT: 없음
PUSH: 없음
REMAINING RISKS: 약10mm는 S22 디스플레이 정보 기반 계산값이며 실제 자로 측정하지 않음. 테스트14 PASS /1 SKIP.
NEXT ACTION: 사용자 시각 확인 후 필요한 미세 조정

10mm는 S22 현재 화면 375.78dpi, devicePixelRatio2.8125를 기준으로 10/25.4*375.78/2.8125 ≈52.6dp로 계산해53dp 적용. 다른 기기·디스플레이 설정에서는 실제 길이가 달라질 수 있음.
기존 데이터·로그인·빌드27 전환 복구·예시5개는 유지. adb install -r만 사용. A33/운영 서버/스토어 변경 없음.

최초 표준 설치기의 빌드 단계가 Tool failed(1)로 중단되어 설치하지 않음. 동일 Release 빌드를 비밀값 필터와 함께 재실행해 APK 성공 확인. 재사용 APK 설치에서도 서명·패키지·버전·non-debuggable 검증과 대상기기 지정은 유지하고, 이미 완료된 pub get/build 명령만 생략함.

후속 실기기 시각 확인 완료: S22 공포😨 아이콘·공포 선택 상태 확인. 새 대화를 열어 입력칸·보내기·마이크가 하나의 둥근 테두리 안에 배치되고 짧은 하이라이트가 표시되는 화면 확인. 테스트 문구를 입력하거나 AI 요청을 전송하지 않음.
