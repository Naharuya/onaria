# 마음대화 → 말씀·실천 전환 복구

PROJECT: ONARIA
CURRENT COMMIT: 40cd65851553238c426b32f5af2639e76f24f64b
ISSUE FOUND: 대화는 되지만 말씀·실천 화면으로 넘어가지 않음
PRIORITY: P1 핵심 기능
ROOT CAUSE: continueConversation 응답을 최대5회까지 받은 뒤 상태 머신이 종료하고 입력창을 숨김. 오프라인 고강도 감정 경로도5회 후 종료하므로 다음 단계 선택 불가.
IMPLEMENTED: 일반 대화 최대횟수 도달 시 종료 대신 말씀 선택 화면으로 전환. 오프라인 고강도5회 후도 같은 선택 제공. 명시적 일반 종료에는 선택형 말씀/실천 연결 버튼 추가. 위기 분기와 명시적 종료 상태는 유지.
CHANGED FILES: lib/src/conversation/conversation_machine.dart, lib/features/conversation_page.dart, test/conversation_machine_test.dart, test/conversation_continuation_test.dart, pubspec.yaml
TEST: 상태 머신·온라인/오프라인5회→말씀 선택→작은 실천·AI전송 거부·위기 우선·화면 이탈·예시5개 회귀 16 PASS / 1 SKIP. dart analyze No issues found.
BUILD: Release 1.0.0+27 빌드·서명·패키지 검증 및 S22 adb install -r 성공
DEVICE: Galaxy S22 Ultra SM-S908N R3CT10BVG6V만 지정
API: 변경 없음
CI: NOT RUN
COMMIT: 없음
PUSH: 없음
REMAINING RISKS: 사용자 실제 서버 응답으로 실기기 전체 대화 재확인 필요
NEXT ACTION: 사용자 실제 대화에서 말씀·실천 연결 확인

디자인과 예시5개 복원을 유지. 기존 서명과 패키지로 adb install -r만 실행. A33/다른 기기/운영 서버/스토어 변경 없음.
5회 뒤에는 말씀을 자동 강제 표시하지 않고 읽기/건너뛰기 선택을 제공. 위기 감지 시 계속해서 위기 UI가 우선하며 일반 다음 단계 패널은 riskLevel0에서만 표시.
