# ONARIA 모바일 Quiet Light · S22 단독 설치

PROJECT: ONARIA
CURRENT COMMIT: 40cd65851553238c426b32f5af2639e76f24f64b
ISSUE FOUND: 홈페이지 디자인을 모바일 앱에 적용하고 S22에만 설치 요청
PRIORITY: P2 UI/UX
ROOT CAUSE: 기존 앱의 우주·행성 표현과 새 홈페이지의 고요한 빛 표현 간 차이
IMPLEMENTED: 정적 빛 배경, 기독교 마음돌봄 브랜드 문구, 홈페이지와 같은 제목·서체 위계·카드 여백, 빌드25
CHANGED FILES: lib/app/space_scaffold.dart, lib/features/check_in_page.dart, pubspec.yaml
TEST: 변경 전 201 PASS / 1 SKIP; 변경 후 관련 23 PASS; installer 15 PASS / 1 SKIP
BUILD: Release APK 1.0.0+25 빌드·서명·패키지·non-debuggable 검증 PASS
DEVICE: Galaxy S22 Ultra SM-S908N, R3CT10BVG6V에만 adb install -r 성공, versionCode25 및 앱 실행 확인
API: https://api.onaria.ai.kr 유지
CI: NOT RUN
COMMIT: 없음
PUSH: 없음
REMAINING RISKS: 로그인·대화·탈퇴 등 실기기 전체 기능 재검증은 NOT RUN
NEXT ACTION: 사용자의 S22 디자인 확인 후 후속 개선

정적 분석: flutter analyze lib test example --no-fatal-infos, 오류0 경고0 정보성49.
360/390/430px 레이아웃, 홈 화면, 테마, 계정 메뉴, 대화·안전 회귀 포함.
백업: build/design-backups/20261030-213854
설치 경로: node scripts/android-release.mjs R3CT10BVG6V. 기존 releaseCert/패키지/버전 검증 후 adb -s 대상 install -r. 삭제·초기화 금지.
A33 및 다른 기기에 설치하지 않으며, iOS/스토어/서버는 이번 작업에서 변경하지 않음.
영상·지속 애니메이션 대신 정적 CustomPainter를 사용해 모션 감소 환경과 추가 디코딩 비용을 고려함.
