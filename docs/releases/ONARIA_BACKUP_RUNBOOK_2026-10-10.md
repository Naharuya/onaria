# ONARIA 주기 백업 운영 준비

## 현재 확인 사실 (2026-10-10)

- Production `onaria-backend.service`는 active.
- 운영 `/health`는 현재 `{"status":"ok"}`이며 1.0.0(19)는 아직 배포되지 않음.
- ONARIA 전용 backup/retention timer 또는 cron은 확인되지 않음.
- 배포 시점 보호 백업은 `/opt/onaria-backups`, `/opt/onaria/deployments`, `/opt/onaria/rollout-*`에 존재.
- DB 사본은 2026-10-06~07 범위에서 확인됨.
- 현재 디스크는 약 48GB 중 44GB 여유.
- 기존 백업을 삭제하거나 보유기간을 적용하지 않음.

## 준비된 자동 백업

`backend/scripts/backup_databases.js`는 다음 3개 SQLite DB를 SQLite Online Backup API로 별도 디렉터리에 복사한다.

- members.sqlite
- member-sessions.sqlite
- ai_usage.sqlite
- deletion-manifest.sqlite (삭제명부 기능 배포 후)

현재 Production에 설치된 2026-10-10 최초 backup script는 앞의 3개 운영 DB만 백업한다. `deletion-manifest.sqlite`는 아직 Production에 존재하지 않으므로 Release 후보 배포와 함께 backup script를 갱신한 뒤 4개 DB 백업을 검증한다.

각 백업은:

- 백업 디렉터리 0700
- DB 파일 및 manifest 0600
- SQLite `quick_check=ok` 검증
- SHA-256 기록
- 일부 실패 시 해당 회차 디렉터리 제거
- live data 디렉터리 내부를 backup root로 지정하는 설정 거부
- 기존 백업 자동 삭제 없음

## systemd 후보

- `ops/onaria-backup.service`
- `ops/onaria-backup.timer`
- 매일 03:17 KST + 최대 10분 random delay
- missed run은 Persistent=true로 다음 부팅/활성화 시 실행
- live DB는 read-only path, backup root만 write 허용

## Production 적용 전 승인 필요 작업

아래는 운영 서버 변경이므로 별도 승인 후에만 실행한다.

1. `/opt/onaria-periodic-backups`를 ubuntu:ubuntu, 0700으로 생성.
2. Release 후보에 backup script 포함 후 Production backend에 배포.
3. service/timer unit을 `/etc/systemd/system`에 설치.
4. `systemctl daemon-reload`.
5. 먼저 `systemctl start onaria-backup.service` 1회 수동 실행.
6. 생성된 manifest, 권한, quick_check 결과 검증.
7. 복원은 운영 DB에 덮어쓰지 않고 별도 임시 경로에서만 검사.
8. 검증 PASS 후에만 timer enable/start.
9. 24시간 뒤 다음 회차 생성 확인.

## 아직 적용하지 않는 것

- 백업 자동 삭제/30일·37일 만료
- 회원/세션/usage 자동 파기
- deletion manifest 운영 연결
- 운영 DB 복원
- Production 코드 배포
- 서비스 재시작

보유·파기 기간은 전체 복제본과 복원 경로가 확인된 뒤 별도 Gate에서 확정한다.
