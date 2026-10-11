# ONARIA 보유·파기 기준 적용 후보 — 2026-10-11
사용자 승인: 제안한 기준대로 적용. HEAD 1aef3815c8e25022a948c4307e1c755e5cc8507b.
이번 결과는 로컬 구현 및 운영 원본 기반 격리 검증이다. 운영 적용·재시작·commit/push는 기존 HOLD 유지.

## 구현
- 일반 서비스 로그와 정기 백업: 14일 기준, 기간 경과 자료는 다음 일일 작업에서 파기. 매 순간 14일 이내 완전 삭제를 보장한다는 문구를 사용하지 않는다. 작업 장애 시 실패를 감시해야 한다.
- 백업: manifest/hash/파일 검증 후 정리. 알 수 없는 파일, 변조, symlink, 비어 있지 않은 WAL이 있으면 중단.
- 백업 생성·정리 공통 잠금. 충돌 및 중복 실행 차단. 충돌/비정상 종료 후 lock은 운영자가 프로세스 종료 확인 후 검토해야 한다.
- 세션: 기존 최대30일 유효기간 유지, 로그아웃·탈퇴 시 무효화, 만료 기록 일일 삭제.
- 사용량: 기존62일 원장 설정 유지. 기존 원장 adapter로 pending reservation 복구 후 기한 경과 요청/child calls 정리.
- 삭제 명부: 회원번호·삭제시각만 저장. 백업 파기 성공 후 복원 가능 최저 시점을 먼저 올리고14일 경과 명부 정리.
- 복원: 최신 운영 삭제 명부 필수, 도입 전/14일 경과 백업 거부, 탈퇴 회원 제거, 새 회원 ID 재사용 방지. 이전 세션 복원 금지. offline 후보만 생성하며 활성화 전에 최신 명부 재대조 필요.
- 회원 DB secure_delete 적용 후보. DB/WAL/파일시스템에서 즉시 물리적 완전 소거가 확인됐다고 주장하지 않는다.
- 공개 privacy/support/account-deletion 고지에 SDK·보유·삭제 설명 반영 후보. 운영 확인 전에 게시하지 않는다.
- ONARIA 전용 journald namespace 및 nginx 최소 접속 로그·전용logrotate 후보. 공용 journald/nginx 로그 파기 설정은 변경하지 않는다.
- 관리자 개인정보 접근 감사 기록은 일반 서비스 오류 로그와 구분한다. 해당 감사 기록의 수집 범위/적용 의무/별도 보유기간과 nginx error log의 민감 URL 노출 여부는 최종 출시 전 확인 대상이다.

## 검증
- 변경 전 관련7 PASS.
- 최종 로컬 전체 백엔드517 PASS /0 FAIL.
- 운영 src 원본을 별도 격리 사본에 복사하고 좁은 운영 후보만 적용:22 PASS /0 FAIL.
- 운영 후보8개JS syntax PASS. 실제 nginx/systemd/logrotate 환경검증은 배포 전 Gate.
- 앱 변경 없음: Build24 유지, 앱 재빌드·재설치 미실행.
- 운영 읽기 전용: 만료 세션0,62일 경과 사용량0; 백업2세트(각3DB),14일 경과 세트0.
- 중요 차이: 운영 server.js에 삭제 명부 연결 없음, deletion-manifest.sqlite 없음. 소급 삭제 이력을 추측하지 않는다. 새 명부 도입 전 백업은 자동 복원에서 차단한다.

## 준비된 산출물
- docs/releases/patches/ONARIA_RETENTION_PRODUCTION_CANDIDATE_2026-10-11.patch
- build/onaria-retention-candidate: production 서버 원본 기반8개JS 및 ops 설정/hash 목록. .before 원본은 배포 제외.
- build/onaria-retention-production-fixture: 운영 원본 기반 격리 테스트 사본.
- backend/src/privacy/backup_retention.js
- backend/scripts/retention_maintenance.js
- backend/scripts/prepare_member_restore.js
- backend/test/retention_maintenance.test.js
- ops/onaria-retention.service, timer, ONARIA 로그 설정.

## 운영 적용 범위와 순서
기존 미커밋 작업184개를 통째로 배포하지 않는다. 회원통합은 비활성 유지. 회원 DB 스키마/서명/앱빌드 변경 없음.
1. 독립 후보 변경을 CI artifact 방식으로 생성. 기존 commit/push HOLD를 해제할 경우에도 대상 파일만 포함.
2. 운영 원본 hash 및 경로 일치 확인. 변경 전 코드/설정 복구 사본에는 보유기간14일을 적용하고 회원DB를 무제한 별도 복사하지 않는다.
3. 후보 deletion_manifest, backup_retention, maintenance, restore, backup scripts 설치. server.js는 삭제 명부 연결만, member_store.js는 secure_delete만 적용.
4. ONARIA 전용로그 namespace/config와 nginx ONARIA host4개 설정만 적용. nginx -t, systemd-analyze verify, logrotate -d 통과 후 반영.
5. ONARIA backend1회 재시작으로 새 명부 생성·연결. 다른 프로젝트 서비스는 재시작하지 않는다.
6. 새4DB 백업 생성 및 integrity 확인. 정리 dry-run count 확인 후 apply, timer active 확인. 현재 점검 기준 삭제 예정 만료 데이터0. 실제 실행 시 새로 계산한다.
7. 격리된 새 백업 사본으로 탈퇴/복원 차단 검증. 실제 회원을 테스트 목적으로 탈퇴시키지 않는다.
8. 정책은 운영 실행 확인 후 갱신. public /privacy, /support, /account-deletion HTTPS 및 가입·로그인 회귀 확인.
9. 과거 공용로그/수동 백업 복사본 잔존·감사로그 분류 및 SDK 실제 데이터 흐름 검증 후 App Privacy 게시/심사 제출 Gate 재판정.

## 승인 경계
AGENTS.md: “production server를 자동 변경하거나 재시작하지 않는다.”
AGENTS.md: “production DB migration ... 운영 서버 재시작 ... 데이터 삭제 가능 작업은 사용자 승인 전에 실행하지 않는다.”
기준 적용 승인을 개발·검증에 반영했다. 기존 운영 변경·재시작 및 commit/push HOLD 해제 범위를 명확히 확인하고 위 좁은 변경으로 배포한다.


## Authorized production deployment — 2026-10-11

User authorized narrow production release, branch commit/push and one backend restart. Deployed commit: 68fcac67ca8875c8512e19bef928d602040c0c38. GitHub Actions run 38142470290 completed successfully; downloaded artifact onaria-retention-release was checksum and exact-commit verified. Deployment allowlist contained 19 files. Original dirty checkout was preserved.

Validation: isolated release backend 471 PASS / 0 FAIL; nginx configuration and logrotate validation passed. Backend restarted once, health status ok. Public /health, /privacy, /support and /account-deletion returned HTTP 200. New latest backup contains 4 SQLite databases including deletion manifest. Both daily retention timers active/enabled; backup, regular retention and legacy backup maintenance Result=success. Dry run: 3 regular snapshots, 7 legacy directories, 0 aged backup candidates, 0 expired sessions, 0 usage entries older than 62 days, 0 aged deletion entries. No real member deletion test performed.

Account merge remains disabled; Build24 unchanged. Earlier user-reported S22, A33 and iPhone login confirmation is prior evidence, not a new real-device provider login test after this deployment.

Remaining release gate: historical ONARIA messages remain in the shared system journal (earliest observed 2026-09-21). New ONARIA journal namespace is isolated with a 14-day retention setting; this does not purge historical shared journal files. Global vacuum was not run because those files also contain other projects' records. Therefore historical log cleanup and App Store privacy declaration versus actual SDK data flow remain unverified; App Privacy publication and final App Review submission were not performed.

Incident: initial commit c7c0875 was pushed despite a failed migration test due to missing fail-fast shell handling. It was never deployed. Migration fixture alignment and fail-fast handling were corrected; only the successful exact-commit CI artifact above was deployed.


## Final follow-up status (supersedes historical-journal HOLD)

Selective cleanup completed: exclusive192 plus mixed3,265 aged ONARIA entries removed; all2,284 unrelated mixed-file records retained with fields and timestamps verified. Daily maintenance active; aged ONARIA application entries zero. Exact helper CI commit2531cd6de9752249baef6b244a0aec0b96036c90 / run38144302570 success. Initial EXDEV failed before archive replacement, fixed with same-filesystem staging. The proposed mixed whole-file purge was not executed. Final privacy draft is11 linked types, no tracking; Other User Content removed after request-scoped storage verification. Public access-log disclosure deployed at33b10d60. Remaining App Store gate is action-time confirmation of Apple publication agreement; privacy Publish and review submission not completed. See ONARIA_STORE_PRIVACY_FOLLOWUP_2026-10-11.md for final matrix and operational evidence.


## Final submission update — 2026-10-11 23:11 KST

Supersedes the action-time agreement HOLD above. User explicitly approved Apple publication agreement and Build24 review submission. Privacy publication completed (console: SeJin Jo published moments ago). Version1.0 / Build1.0.0(24) added and final Submit for Review completed. Console confirmed one item submitted and Waiting for Review. Submission ID: d7f03fc5-6f1b-4a62-94a0-7a6464a08c34. Manual release remains selected; approval will not automatically publish the app. Screenshot: onaria-build24-submitted-20261011.jpg. No app rebuild, production change or new device test in this final submission step.
