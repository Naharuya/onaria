# 프로젝트 폴더 구조

`source/`는 ONARIA의 독립 Git 저장소다. 상위 관리 저장소에 소스를 추가하거나 서브모듈로 바꾸지 않는다.

| 위치 | 역할 |
| --- | --- |
| `lib/` | Flutter 앱과 기능 구현. `marketing_demo.dart`는 로컬 마케팅 데모 진입점 |
| `test/`, `example/` | Flutter 회귀 테스트와 예제 |
| `assets/` | 앱 이미지 등 원본 리소스 |
| `android/`, `ios/`, `web/` | 플랫폼 빌드 설정 |
| `backend/src/`, `backend/public/` | API 서버 및 웹·관리자 화면 |
| `backend/test/`, `backend/e2e/` | 서버 단위·통합 테스트와 브라우저 테스트 |
| `backend/config/`, `backend/corpus/`, `backend/evaluation/` | 검색 설정, 자료, 평가 근거. 단순 캐시로 취급하지 않음 |
| `backend_contract/` | 앱·서버 응답 계약 |
| `scripts/` | 배포 패키징, 안전한 Android 업데이트, 배포 회귀 테스트 |
| `script/` | 기존 운영·연결 도구 및 아이콘 생성 도구. 기존 참조를 유지 |
| `docs/guides/` | 반복해서 참고하는 개발 지침 |
| `docs/releases/`, `docs/archive/` | 버전별 검증 기록과 과거 개발 이력 |
| `.github/workflows/` | CI 정의 |
| RAMI | 독립 저장소 `Naharuya/RAMI`에서 관리 |

## 생성 파일과 보존 파일

`build/test_cache/`, `build/unit_test_assets/`, `build/*.cache.dill.track.dill`은 Flutter 테스트·컴파일이 다시 생성한다. 테스트나 빌드가 실행 중이지 않을 때 정리할 수 있다. `.DS_Store`, `__pycache__/`, `*.py[cod]`는 Git에서 제외한다.

`build/app/outputs/`, `build/ios/`, 웹 검증 보고서와 배포 ZIP은 검증·복구 근거일 수 있으므로 일괄 삭제하지 않는다. `.dart_tool/`, `node_modules/`, `ios/Pods/`와 Gradle 캐시는 오프라인 개발에 필요할 수 있어 이번 정리에서는 유지했다.

미커밋 파일과 `*.before_*` 백업은 작업 의도를 확인하기 전까지 보존한다. 환경 파일, DB, 서명키, 인증정보, 심볼릭 링크는 정리 대상으로 삼지 않는다.

## 테스트 위치

설치된 의존성을 사용하며 아래 명령은 `source/` 기준이다.

```bash
flutter test --no-pub
flutter analyze --no-pub lib test example --no-fatal-infos
node --test scripts/android-release.test.mjs
```

백엔드에서는 `npm test`, `npm run test:web`, `npm run test:web:performance`를 실행한다. 브라우저 검사는 로컬 fixture 서버와 설치된 브라우저가 필요하다. Chrome을 사용할 때는 `WEB_BROWSER_CHANNEL=chrome`을 설정한다. 이 결과는 실제 AI 제공자·운영 서버·실기기 검증과 구분한다.

`scripts/test_deploy_cafe24.py`는 Linux 전용 배포 fixture 검사다. macOS 기본 `realpath`는 배포 스크립트의 GNU 옵션을 지원하지 않으므로 Linux CI에서 검증한다.


## ARI 다중 장비 · GitHub 협업 구조

2026-09-21부터 프로젝트 작업 기준은 아래 구조를 사용한다.

```text
Windows VS Code
C:\ari-server\projects
        │
        │ commit / push / fetch / pull
        ▼
┌───────────────────────────────┐
│          GitHub Central       │
│                               │
│ Naharuya/onaria               │
│ Naharuya/RAMI                 │
│ Naharuya/k-stock-ai           │
│ Naharuya/Beavers              │
│ Naharuya/Lightshare           │
└───────────────────────────────┘
        ▲                 ▲
        │                 │
        │                 │ GitHub API / branch / commit / PR
        │                 │
Mac VS Code               ARI
/Users/ari/ari-server/projects
```

GitHub를 중앙 기준점(Source of Truth)으로 사용한다.

- 사용자는 Windows와 Mac 어느 쪽에서도 VS Code로 개발할 수 있다.
- ARI는 GitHub를 통해 브랜치, 커밋, PR, 리뷰 및 문서 변경을 수행한다.
- Windows와 Mac 사이에 프로젝트 파일을 직접 복사해 최신본을 결정하지 않는다.
- 누가 작업하든 변경은 Git commit과 push로 GitHub에 남긴다.
- 다른 장비에서 이어서 작업할 때는 fetch 후 상태를 확인하고 `git pull --ff-only`를 우선한다.
- 미커밋 작업이 있는 장비에서 강제 reset, clean, checkout, 자동 stash를 수행하지 않는다.

### 장비별 프로젝트 루트

```text
Mac
/Users/ari/ari-server/projects/
├── onaria
├── rami
├── k-stock-ai
├── beavers
└── lightshare

Windows
C:\ari-server\projects\
├── onaria
├── rami
├── k-stock-ai
├── beavers
└── lightshare
```

| 프로젝트 | GitHub | 기본 브랜치 | Mac 경로 | Windows 경로 |
| --- | --- | --- | --- | --- |
| ONARIA | `Naharuya/onaria` | `main` | `/Users/ari/ari-server/projects/onaria` | `C:\ari-server\projects\onaria` |
| RAMI | `Naharuya/RAMI` | `main` | `/Users/ari/ari-server/projects/rami` | `C:\ari-server\projects\rami` |
| K-Stock AI | `Naharuya/k-stock-ai` | `master` | `/Users/ari/ari-server/projects/k-stock-ai` | `C:\ari-server\projects\k-stock-ai` |
| BEAVERS | `Naharuya/Beavers` | `main` | `/Users/ari/ari-server/projects/beavers` | `C:\ari-server\projects\beavers` |
| Lightshare | `Naharuya/Lightshare` | `master` | `/Users/ari/ari-server/projects/lightshare` | `C:\ari-server\projects\lightshare` |

현재 GitHub에서 별도 `MindBible` 저장소는 확인되지 않았다. 별도 저장소가 생기거나 기존 저장소와의 관계가 확정되면 이 표를 갱신한다.

### 공통 Preflight

각 장비와 ARI는 작업 시작 전 최소한 아래를 확인한다.

```bash
git remote -v
git branch --show-current
git status
git rev-parse HEAD
git fetch origin
```

프로젝트 경로, 저장소, 브랜치, 운영 대상이 맞지 않으면 개발·배포를 진행하지 않는다.

### ONARIA 현재 운영 인프라

```text
Gabia DNS
   │
   ├── onaria.ai.kr
   ├── www.onaria.ai.kr
   └── api.onaria.ai.kr
             │
             ▼
       1.201.113.102
       ari-prod-01
       Ubuntu
             │
        nginx 1.24.0
             │
             ▼
       ONARIA backend
```

2026-09-21 확인 기준:

- 운영 서버는 `ari-prod-01`, 공인 IP는 `1.201.113.102`.
- OS는 Ubuntu이고 HTTPS front는 nginx 1.24.0이다.
- 세 도메인은 모두 `1.201.113.102`로 해석된다.
- Let’s Encrypt 인증서 SAN에는 `onaria.ai.kr`, `www.onaria.ai.kr`, `api.onaria.ai.kr`가 모두 포함된다.
- 루트와 `www` HTTPS 200 응답을 확인했다.
- 이전 `104.105.128.84 / Rocky / Apache` 구조는 현재 운영 기준이 아니다.
