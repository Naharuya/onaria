# Google·네이버 인증 대기 복구

카카오는 사용자 로그인 성공 확인. Apple은 invalid_client 해소 후 계정 정보 확인 화면까지 진입했지만 사용자 인증 성공은 미확인. Google·네이버는 인증 대기 화면이 계속 표시된다는 사용자 제보로 확인했다.

네이버: 설치된 0.4.3+9 APK의 naver_client_secret 리소스가 비어 있음을 확인했다. 이전 0.4.2+8 설치 APK에는 기존 키가 남아 있어 같은 ONARIA 키를 출력 없이 복구했다. 유실 경위는 아직 확정하지 못했다. Flutter SDK 경로 설정과 분리하기 위해 local.properties 대신 Git에서 제외된 android/naver.properties에 보관하고 Gradle에서 먼저 읽는다. 기존 local.properties 경로는 호환용으로 유지한다. 이 로컬 파일은 Git/CI에 포함하지 않는다.

Google: 앱과 서버의 웹 client ID 일치를 확인했다. 네이티브 계정 선택 Activity 기록은 있었지만 실패 코드나 콜백 누락 원인은 확정하지 못했다. GoogleSignIn singleton의 초기화 Future를 여러 서비스 인스턴스와 시도에서 공유하도록 수정했다. 초기화 실패 시 캐시를 해제하고 15초 제한을 적용한다.

Google·네이버 사용자 인증은 각각 90초를 기다린 뒤 명시적 지연 메시지로 종료한다. 기존 페이지의 finally가 로딩을 해제한다. 제한 이후 SDK가 늦게 반환한 인증정보로 서버 로그인이나 가입을 시작하지 않는다. Dart의 timeout은 네이티브 UI 자체를 닫거나 요청을 취소하지 않으므로 지연 안내 이후 기존 로그인 창을 닫고 다시 시도해야 한다. SDK에서 응답이 오지 않는 근본 원인을 모두 해결했다고 표시하지 않는다.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 7b78ac3154fbe83cbd2e4d2a0ed2b25edb086018
ISSUE FOUND: Google·네이버 인증 무한 대기 및 네이버 릴리스 리소스 누락
PRIORITY: P1 인증
ROOT CAUSE: 네이버 설치 APK에 키 누락(유실 경위 미확정); 네이티브 요청에 완료 시간 제한 없음; Google 실패 원인 미확정
IMPLEMENTED: 기존 네이버 키 복구와 별도 로컬 설정; Google 초기화 공유; 인증 완료 제한
CHANGED FILES: Google/Naver login services; Gradle; gitignore; pubspec; 회귀 테스트; 이 문서
TEST: 관련 회귀 테스트 2 PASS; Mac 관련 Flutter 8 PASS; 전체 Flutter 134 PASS 및 기존 1 SKIP; analyze 오류·경고 0 및 기존 info 16
BUILD: Android 0.4.4+10 release PASS; APK 네이버 리소스가 복구한 설정과 일치
DEVICE: SM_S908N 0.4.4+10 adb install -r 및 앱 실행 PASS; 인증서·패키지·버전·비디버그 검증; 사용자 로그인 성공 미확인
API: 서버 Google audience 일치; Naver verifier 활성화; 이번 서버 변경 없음
CI: 게시 후 정확한 커밋 확인; 결과는 별도 보고
COMMIT: 검증 후 기록
PUSH: 기존 PR 후속 커밋 게시
REMAINING RISKS: 실제 Google·네이버 사용자 인증 성공 미확인; 네이티브 timeout이 SDK 요청을 취소하지 않음; Google OAuth 인증서 등록 상태 미확인
NEXT ACTION: 릴리스 설치·네이버 리소스 확인 후 사용자 로그인 재시험
```
