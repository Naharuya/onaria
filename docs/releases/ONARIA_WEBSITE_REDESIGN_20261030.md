# ONARIA 홈페이지 디자인 적용 · 2026-10-30

PROJECT: ONARIA
CURRENT COMMIT: 40cd65851553238c426b32f5af2639e76f24f64b
ISSUE FOUND: 새 디자인을 운영 홈페이지에 적용 요청
PRIORITY: P2 UI/UX
ROOT CAUSE: 기존 홈페이지를 새 브랜드 디자인으로 갱신
IMPLEMENTED: 홈페이지 루트 전용 템플릿과 버전별 정적 자산, /webapp/ 시작 버튼 및 법정 안내 링크
CHANGED FILES: backend/src/website.js, backend/public/website/redesign-20261030/
TEST: 스테이징 7경로 PASS, 운영 7경로 200, 홈페이지 CSS/JS/이미지 200, 데스크톱 시각 확인
BUILD: buildless, node --check PASS
DEVICE: 모바일 실기기 NOT RUN
API: health ok, version 1.0.0 build20, API 코드/DB 변경 없음
CI: NOT RUN
COMMIT: 없음
PUSH: 없음
REMAINING RISKS: 모바일 실기기 및 자동재생 차단 환경 검증 남음
NEXT ACTION: 정확한 변경만 리뷰 후 커밋 및 CI 확인

운영 백업: /opt/onaria/deployments/website-backups/20261030T122157Z
복구: 백업 website.js를 /opt/onaria/backend/src/website.js에 복원하고 onaria-backend 재시작. 기존 자산은 보존.
운영 반영 시 최초 HTML의 CSS/JS 경로 중복을 발견해 정정했으며, 최종 Mac 소스에도 같은 정정을 반영함.
다른 미커밋 파일은 보존했으며 서비스 재시작 외 운영 설정·인증·DB는 변경하지 않음.
