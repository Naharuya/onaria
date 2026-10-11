# ONARIA Apple 모의 격리 재현 절차

실제 Apple 검증은 보류한다. 이 절차는 모의 trusted identity만 사용하며 Apple 인증·철회·운영 DB에 연결하지 않는다. 현재 설치 build18을 유지한다.

## 실행
프로젝트 루트에서 기존 의존성을 사용한다. 운영 .env를 읽거나 복사하지 않는다.
```sh
node --test backend/test/apple_isolation.test.js
node --test backend/test/durable_deletion_lab.test.js backend/test/isolated_cost_adapter.test.js backend/test/retention_plan.test.js
```
백엔드 전체 회귀는 backend 폴더에서 `npm test`로 실행한다. 테스트용 loopback 서버 권한이 필요한 환경에서는 이를 운영 API 실패와 구분한다.

## 비밀값 없는 설정 예시
```js
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { prepareAppleIsolation } from './backend/src/privacy/apple_isolation.js';
const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'onaria-apple-isolation-'));
const configuration = prepareAppleIsolation({ directory, env: {} });
// mock-only, realAppleAllowed=false. 운영 설정/키를 주입하지 않는다.
// 회원·세션·usage·manifest SQLite 및 backup 폴더가 분리된다.
```
예시는 저장 경로 구성만 한다. DB handle을 닫은 뒤 직접 만든 임시 폴더만 정리한다. 실제 환경 생성·정리는 위 테스트가 자동 수행하므로 재현에는 테스트 명령을 우선 사용한다.

## 수용 기준
- 운영 경로/설정 주입 및 기존 대상 재사용 차단.
- 모의 회원/세션 생성→탈퇴→이전 DB 복원→독립 명부 재적용.
- 신규 세션 차단, 오류 rollback/재시도, 재시작 후 복구.
- 독립 프로세스 경쟁 결과는 완료1/중복1, 새 세대 보존.
- 비용 association 미확인/pending 차단, FK 실패 전체 rollback·다른 owner 보존.
- 실제 Apple/외부 네트워크 호출 없음.

## 실제 검증 차단 조건
콘솔 전체 Return URL 미확인, 격리 callback 등록 증거 미확보, 별도 테스트 Apple 계정·기기/서비스 준비 미완료. 운영 callback을 격리용으로 사용하지 않는다. 설정 변경·실제 인증·철회·회원삭제는 별도 허용 전 실행하지 않는다. 백업30일/명부37일 적용 없음.
