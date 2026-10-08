# AUTO_DEV_LOG

## 2026-10-08 — 소셜 가입 인증 오류 후 재인증

- 기준 main: 3fa97ca65f3c24329a22e8f3e66504e670d2f6c9. 별도 작업트리/브랜치.
- 사용자 관찰: Galaxy에서 Apple 인증 후 가입 정보 화면 진입, 가입 완료 시 회원 인증 필요 안내. 15:16 KST 재시도. 사용자 보고만으로 HTTP 상태나 원인을 확정하지 않음.
- 가비아 서버 읽기 전용 조회: 06:14–06:19 UTC 서비스 journal 0행. 최근 200행에 provider_identity_rejected 없음. 요청별 access log 또는 해당 요청 상태는 확인하지 못함. DB/로그 원문/키/토큰 미조회·미출력, 운영 변경 없음.
- 코드: 전화번호 중복은 409와 별도 안내, 이름·교회명 중복 검사는 없음. Android Apple proof는 5분 만료. 가입 완료 401 후 동일 credential 반복 사용은 확인된 복구 문제.
- 수정: 가입 완료 401이면 pending credential만 폐기, 입력값·동의·기존 회원 세션 보존, 제공자 재인증 버튼 표시. 409는 재인증으로 오인하지 않음. 자동 계정 병합/전화번호 중복 제한 완화 없음.
- 검증: mock widget에서 인증 후 401 → 입력/체크 보존 → 재인증 → 새 credential 전송; 409 구분. Backend Apple Android/member store 14 PASS. 전체 Flutter/분석 결과는 PR 검증과 함께 기록.
- 운영 배포 및 Android 설치, Apple 실제 가입/연결 검증 미실행. 기존 TestFlight 12는 iOS 서명 권한 수정본이며 이번 UI 수정은 포함하지 않음.
