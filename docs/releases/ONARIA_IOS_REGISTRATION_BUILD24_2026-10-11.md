# ONARIA iOS Build24 등록 진행

2026-10-11 Asia/Seoul. 사용자 iOS 앱 등록 진행 승인.

- 현재 branch codex/apple-android-20261006, HEAD 1aef3815c8e25022a948c4307e1c755e5cc8507b. 기존 dirty 180개 보존.
- App Store용 1.0.0(24), com.onaria.app 새 Archive/IPA 생성 성공. 기존 배포 설정/서명 재사용. strict/deep codesign PASS, team BJL8U6B46S, get-task-allow false, ProvisionedDevices 없음.
- xcodebuild App Store Connect 업로드 exit0, Upload succeeded, EXPORT SUCCEEDED. 처리 완료 및 심사 연결은 별도 확인.
- 기존 앱 Apple ID 6819979630, SKU ONARIA_IOS 확인. 버전1.0 제출 준비 중, 연결 빌드19 확인.
- 콘솔 심사 메모를 소셜 인증/비로그인 핵심 기능/계정 관리/탈퇴/회원통합 비활성 설명으로 갱신 저장. ONARIA 자체 ID/password 미지원이므로 로그인 필요 체크 해제. 수동 출시 유지.
- iPhone/iPad 스크린샷 각5장 등록 확인. 모든 이미지의 최신 Build24 일치 검증은 미완료.
- 연령 등급18+, 대한민국19+ 표시 확인.
- App Privacy12개 데이터 유형 등록. 위치/기기 ID/이메일/진단 등의 SDK 및 운영 실제 수집 대조 필요. 확증 없이 고지 삭제/게시하지 않음.
- S22/A33 로그인 사용자 확인. provider별 조합 미지정. Build24 iPhone 실제 로그인/가입/탈퇴 검증 미확인.
- 최종 심사 제출 NOT RUN. 운영 배포/DB변경/회원통합/commit/push 없음.

## 다음 확인
Apple 빌드 처리 완료 및24 연결; SDK 수집 고지 대조; iPhone 소셜 로그인 검증; 최종 제출 필수 항목 검증.

## 콘솔 접수 확인
Build24 1.0.0, 생성일 Oct11 2026 9:13PM, 처리 중 표시 직접 확인. 아직 설치 가능/심사 빌드 연결/최종 심사 제출 완료 아님.

## 후속 진행 — Build24 연결 완료
- 사용자 보고: S22/A33/iPhone 세 기기 로그인 성공. 제공자별 전체 조합 및 탈퇴 검증으로 확대 해석하지 않음.
- Apple Build24 처리 완료, 암호화 설문 저장, 버전1.0 심사 빌드24 연결 및 저장 직접 확인.
- 대한민국만 배포되는 설정 확인. 수동 출시 유지.
- App Privacy 기기 ID/기타 사용 데이터의 분석 + 앱 기능 목적 저장 확인. 개인정보 전역 게시와 최종 심사 제출은 미실행.
- 배포 Archive의21개 SDK 매니페스트 및 실제 공개 정책 대조. 공개 정책의 SDK 설명 누락과 로그/백업 보유기간 미확정 문구 확인.
- 운영 읽기 전용: 사용량62일 설정; nginx daily rotate14 설정(실제 실행 상태 파일은 권한 거부); journald 시간 제한 미설정; 일일 onaria-backup.timer active 및 최근 서비스 success.
- 백업 위치 /opt/onaria-periodic-backups, 파일20개. backup_databases.js에서 보유기간/파기 코드 확인되지 않음. 추가 수동 복사본까지 전수 검증한 결과는 아님.
- 공개 고지 검토안 작성. 보유기간을 임의 확정하거나 운영 서버를 변경하지 않음.
- 출시 Gate HOLD: 실제 로그/백업 파기 및 탈퇴 후 복원 방지와 공개 고지 일치가 아직 미검증.
- 이번 후속 작업은 콘솔/문서/읽기 전용 확인. 앱 재빌드 및 전체 테스트 재실행 없음. commit/push 보류 유지.
