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
| `rami/` | 별도 앱. ONARIA 정리 범위에서 제외 |

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
