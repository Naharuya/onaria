# ARI 개발 작업 구조도

작성 기준: 2026-09-21

이 문서는 Windows VS Code, Mac VS Code, GitHub, ARI가 동일한 저장소를 기준으로 협업하기 위한 작업 구조를 정의한다.

## 1. 전체 구조

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
        │                 │ GitHub API / PR / commit
        │                 │
Mac VS Code               ARI
/Users/ari/ari-server/projects
```

GitHub를 중앙 기준점(Source of Truth)으로 사용한다.

- 사용자는 Windows와 Mac 어느 쪽에서도 VS Code로 개발할 수 있다.
- ARI는 GitHub를 통해 브랜치, 커밋, PR, 리뷰, 문서 동기화를 수행한다.
- Windows와 Mac 간에 프로젝트 파일을 수동 복사해 최신본을 결정하지 않는다.
- 누가 작업했든 커밋과 push를 통해 GitHub에 변경 이력을 남긴다.

## 2. Mac 프로젝트 경로

```text
/Users/ari/ari-server/projects/
├── onaria
├── rami
├── k-stock-ai
├── beavers
└── lightshare
```

기준 경로:

| 프로젝트 | Mac 경로 |
|---|---|
| ONARIA | `/Users/ari/ari-server/projects/onaria` |
| RAMI | `/Users/ari/ari-server/projects/rami` |
| K-Stock AI | `/Users/ari/ari-server/projects/k-stock-ai` |
| BEAVERS | `/Users/ari/ari-server/projects/beavers` |
| Lightshare | `/Users/ari/ari-server/projects/lightshare` |

## 3. Windows 프로젝트 경로

```text
C:\ari-server\projects\
├── onaria
├── rami
├── k-stock-ai
├── beavers
└── lightshare
```

기준 경로:

| 프로젝트 | Windows 경로 |
|---|---|
| ONARIA | `C:\ari-server\projects\onaria` |
| RAMI | `C:\ari-server\projects\rami` |
| K-Stock AI | `C:\ari-server\projects\k-stock-ai` |
| BEAVERS | `C:\ari-server\projects\beavers` |
| Lightshare | `C:\ari-server\projects\lightshare` |

## 4. GitHub 저장소와 기본 브랜치

| 프로젝트 | GitHub 저장소 | 기본 브랜치 |
|---|---|---|
| ONARIA | `Naharuya/onaria` | `main` |
| RAMI | `Naharuya/RAMI` | `main` |
| K-Stock AI | `Naharuya/k-stock-ai` | `master` |
| BEAVERS | `Naharuya/Beavers` | `main` |
| Lightshare | `Naharuya/Lightshare` | `master` |

현재 GitHub에서 별도 `MindBible` 저장소는 확인되지 않았다. 별도 저장소가 생성되거나 기존 저장소와의 관계가 확정되면 이 문서를 갱신한다.

## 5. 기본 작업 흐름

### Windows 또는 Mac에서 사용자가 작업할 때

```text
VS Code
  ↓
git fetch origin
  ↓
현재 브랜치 / status / HEAD 확인
  ↓
개발
  ↓
테스트
  ↓
git diff / secret 확인
  ↓
commit
  ↓
push
  ↓
GitHub PR / CI
```

### ARI가 작업할 때

```text
GitHub 최신 상태 확인
  ↓
적용되는 프로젝트 규칙 확인
  ↓
별도 작업 브랜치
  ↓
변경
  ↓
검증
  ↓
commit
  ↓
PR
  ↓
CI 확인
  ↓
main/master 병합
```

### 다른 장비에서 이어서 작업할 때

```text
git fetch origin
git status
git branch --show-current
git rev-parse HEAD
git pull --ff-only
```

미커밋 변경이 있으면 강제 reset, checkout, clean, stash를 자동 수행하지 않는다.

## 6. 동기화 원칙

1. GitHub가 중앙 기준점이다.
2. Windows와 Mac 모두 개발 가능한 동등한 작업 환경이다.
3. ARI는 GitHub를 통해 동일한 프로젝트에 참여한다.
4. 작업 시작 전 remote / branch / HEAD / status를 확인한다.
5. 작업 완료 후 테스트 → commit → push 순서를 지킨다.
6. force push를 기본 사용하지 않는다.
7. `git pull --ff-only`를 우선 사용한다.
8. 다른 장비의 미커밋 변경을 덮어쓰지 않는다.
9. 운영 서버는 개발 원본 저장소가 아니다.
10. 운영 배포는 검증된 GitHub 커밋을 기준으로 한다.

## 7. ONARIA 현재 운영 인프라

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
          nginx :443
             │
             ▼
       ONARIA backend
```

2026-09-21 확인 기준:

- 운영 서버: `ari-prod-01`
- IP: `1.201.113.102`
- OS: Ubuntu
- Web/TLS front: nginx 1.24.0
- Let’s Encrypt 인증서 SAN: `onaria.ai.kr`, `www.onaria.ai.kr`, `api.onaria.ai.kr`
- 루트와 www HTTPS 200 확인
- 이전 `104.105.128.84 / Rocky / Apache` 구조는 현재 운영 기준이 아니다.

## 8. Preflight 체크

각 프로젝트 작업 시작 전에 최소한 아래를 확인한다.

```bash
git remote -v
git branch --show-current
git status
git rev-parse HEAD
git fetch origin
```

프로젝트 경로, 저장소, 브랜치, 운영 대상이 일치하지 않으면 개발이나 배포를 시작하지 않는다.
