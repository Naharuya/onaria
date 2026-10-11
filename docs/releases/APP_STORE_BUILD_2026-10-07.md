# ONARIA App Store 빌드 준비 결과

2026-10-07, Asia/Seoul. 사용자가 iOS 출시 준비 진행을 요청했고 App Store Connect에 ONARIA 앱이 이미 등록돼 있다고 확인했다. 콘솔 상태는 아직 직접 확인하지 않았다.

- 앱 공개 변경은 격리 작업트리 `/Users/ari/ARI/worktrees/onaria-app-store-client-20261007`에서 정리했다. 원본 미커밋 변경과 ONARIA 에이전트 작업은 보존했다.
- 앱 commit `1014debff487fdd11625ecccd9d4c47c025aeb5e`, [PR #39](https://github.com/Naharuya/onaria/pull/39). 코드·테스트·공개 성경 출처·Yuna 160·Naver 기존 의존성 pin 포함. 운영 배포 기록과 개인 설정 제외.
- 전체 Flutter 150 PASS / 1 조건부 SKIP. Analyze 오류/경고 0, 기존 info 17개. 비공개 네이티브/빌드 설정은 ignored 확인.
- 최신 iOS simulator 빌드 PASS. iPhone·iPad 첫 화면 실제 캡처 준비, 회원정보 및 눈에 띄는 레이아웃 오류 없음. 추가 기능 전체 스크린샷 세트는 미촬영.
- Release unsigned Archive PASS. `com.onaria.app`, `0.4.4(10)`, SDK `iphoneos27.0`, Flutter App Settings Validation PASS. 포함된 개인정보 매니페스트 21개 정상 파싱.
- 첫 Archive 시도는 Xcode 생성 성공 후 빈 로컬 LaunchImage.imageset 폴더 때문에 Flutter 사후 검사 실패. Git에 없는 빈 폴더를 rmdir한 뒤 동일 commit 재빌드 성공. 소스 수정 없음.
- 기존 서명으로 App Store export 시도는 FAIL: iOS Distribution 인증서 및 com.onaria.app 배포 프로파일 없음. 새 키 생성이나 인증서 교체는 하지 않았다. 계정 로그인 완료 확인 후 배포 인증서/프로파일 준비가 필요하다.
- Archive: 작업트리 `build/ios/archive/Runner.xcarchive`. Export 옵션: `/Users/ari/ARI/deploy-artifacts/onaria-app-store/ExportOptions.plist`. Source 메타데이터: 같은 폴더 `archive-source.json`.
- PR39 CI 전체 PASS: [run 37579005940](https://github.com/Naharuya/onaria/actions/runs/37579005940), backend/Android APK·AAB/iOS simulator 성공. main 병합은 아직 미실행.
- TestFlight 업로드·콘솔 메타데이터 저장·심사 제출은 NOT RUN. 운영 API와 iPhone 탈퇴 서버 검증은 `GABIA_APPLE_DEPLOYMENT_2026-10-07.md` 참조.

## 남은 Apple 계정 작업

Xcode Settings → Accounts에서 ONARIA 팀(BJL8U6B46S) 로그인 완료 확인. 팀 계정에서 Manage Certificates의 기존 Apple Distribution 인증서/개인키를 사용할 수 있는지 확인하고, 없다면 배포용 인증서 발급 경로를 진행한다. 기존 개발 인증서나 키를 삭제·덮어쓰지 않는다. App Store Connect의 기존 ONARIA 레코드에서 빌드번호 중복, 계약, 심사 연락처와 무료 가격을 확인한다. 비밀번호·인증 코드는 기기에서만 입력한다.

스토어 설명·App Privacy·18+ 설문·심사 메모·스크린샷은 `APP_STORE_SUBMISSION_PACKAGE_2026-10-07.md`에 준비했다. 암호화 설문, SDK 실제 수집, 운영 로그/백업 보유 정책은 실제 상태를 대조하여 최종 응답한다. 미서명 Archive를 업로드 완료로 표시하지 않는다.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 1014debff487fdd11625ecccd9d4c47c025aeb5e (앱 후보)
ISSUE FOUND: 현재 팀의 App Store Connect에서 com.onaria.app 레코드 미발견
PRIORITY: 출시 전 필수
ROOT CAUSE: 배포 서명 준비 완료; 기존 App Store 앱 번들 ID/팀 대조 필요
IMPLEMENTED: 격리 앱 커밋/push/PR; 최신 simulator/unsigned Archive; 제출 입력안/스크린샷
CHANGED FILES: 앱 PR39 24파일; 로컬 제출 문서
TEST: Flutter150 PASS/1 SKIP; Analyze0 errors/0 warnings
BUILD: simulator/Archive/App Store IPA 서명 및 프로파일 검증 PASS; 업로드 FAIL (앱 레코드 미발견)
DEVICE: 기존 Release 두기기 설치 완료; iPhone 실제 탈퇴 서버 검증 PASS; TestFlight NOT RUN
API: 가비아 운영 정상; 회원/연결/세션 삭제 확인
CI: PR39 exact commit backend/Android/iOS PASS; run37579005940
COMMIT: 1014debff487fdd11625ecccd9d4c47c025aeb5e
PUSH: PR39 완료; main 병합 미실행
REMAINING RISKS: Apple 로그인·배포 서명·빌드번호 확인·TestFlight·콘솔 개인정보/암호화/연령 설문·최종 심사
NEXT ACTION: TestFlight 처리 완료 확인; 출시 자료 준비 후 App Store1.0 버전에 빌드 연결/검증; 심사 제출 보류
```

## Xcode 팀 연결 이후 결과

사용자가 Xcode 팀 계정 화면을 제공한 후 자동 provisioning으로 App Store export 성공. `onaria.ipa` 배포 코드 서명(strict/deep) 및 프로파일 검증 PASS; get-task-allow false, ProvisionedDevices 없음, bundle com.onaria.app / 0.4.4(10). 기존 인증서 삭제/교체 없음.

App Store Connect 업로드 시도는 FAIL: 현재 팀에서 bundle `com.onaria.app` 앱 레코드를 찾지 못했다(Error Downloading App Information). 사용자 확인의 기존 ONARIA 레코드와 번들 ID/팀 대조 필요. 중복 앱 레코드는 생성하지 않았다. 업로드·심사 제출 성공으로 표시하지 않는다.

사용자가 Team BJL8U6B46S / Bundle com.onaria.app 재확인 후 업로드 재시도: 동일한 App Store Connect 앱 레코드 미발견 오류(exit70). 배포 서명 문제가 아닌 앱 레코드/팀 접근 확인 단계로 구분했다. 새 앱 레코드는 임의 생성하지 않았다.

## 앱 레코드 생성 후 TestFlight 업로드 결과

사용자가 App Store Connect ONARIA 앱 생성 및 콘솔 버전1.0을 확인했다. 같은 검증된 앱 commit에서 `flutter build ipa --release --no-codesign --build-name=1.0 --build-number=11 --dart-define-from-file=.onaria.local.env`로 새 Archive 생성 성공. Flutter가 1.0 입력을 1.0.0으로 정규화하며 실제 Info.plist는 CFBundleShortVersionString=1.0.0 / CFBundleVersion=11이다. pubspec은 기존0.4.4+10이지만 이번 제출 산출물은 명시된 빌드 인자로 버전을 지정했다.

App Store IPA 코드 서명 deep/strict 검증 PASS. 프로파일 Team BJL8U6B46S / application-identifier BJL8U6B46S.com.onaria.app 확인, get-task-allow false, ProvisionedDevices 없음. 업로드 exit0 / Upload succeeded / EXPORT SUCCEEDED. Apple에 패키지가 접수되어 processing 상태이다.

TestFlight 처리 완료 및 설치 가능한 상태는 아직 확인하지 않았다. App Store Connect의1.0 심사 버전에 해당 빌드를 연결하는 단계는 처리 후 확인해야 하며, 업로드 성공만으로 그 연결이 완료됐다고 표시하지 않는다. 심사 제출은 사용자 지시대로 NOT RUN이다.
