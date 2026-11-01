# S22 예시 5개 표시 복원

사용자 확인: 디자인 업데이트 전 예시 문구가 5개씩 표시됐으나 빌드25 설치 후 2개로 줄어듦. 변경된 로컬 소스만 보고 기존 기기 동작과 같다고 설명한 것은 부정확했음.

수정: conversation_page.dart의 감정·강도별 1/2/3개 제한을 제거하고 최대5개 표시. 시작 질문의 기존 감정별 상황 예시는 5개 표시. conversation_question_examples.dart의 서버 제공 예시 상한도3→5. 질문과 무관한 예시를 채워 넣지 않으며 관련 예시가 적으면 존재하는 예시만 사용. 위기 입력 필터와 질문 적합성 검사는 유지.

PROJECT: ONARIA
CURRENT COMMIT: 40cd65851553238c426b32f5af2639e76f24f64b
ISSUE FOUND: 빌드25에서 이전 S22 동작 대비 예시 개수 회귀
PRIORITY: P1 핵심 기능
ROOT CAUSE: 설치한 소스의 감정 강도별 예시 제한
IMPLEMENTED: 5개 표시 복원, 빌드26
CHANGED FILES: lib/features/conversation_page.dart, lib/features/conversation_question_examples.dart, pubspec.yaml, test/conversation_five_examples_test.dart
TEST: 기존 대화·예시26 PASS, 5개 표시3 PASS (슬픔8, 불안10, 복잡함5, 360px), 수정 파일 정적 분석 No issues found
BUILD: Release APK 1.0.0+26 서명·패키지 검증 후 adb install -r 성공, 앱 실행 확인
DEVICE: Galaxy S22 Ultra SM-S908N R3CT10BVG6V만 지정
API: 공식 API 유지, 서버 변경 없음
CI: NOT RUN
COMMIT: 없음
PUSH: 없음
REMAINING RISKS: 사용자 실제 대화 흐름에서 최종 표시 확인 필요
NEXT ACTION: S22에서 예시 개수 사용자 확인

기존 디자인·로그인·기록·인증서·패키지 유지. adb install -r만 사용. A33에는 설치하지 않음.
