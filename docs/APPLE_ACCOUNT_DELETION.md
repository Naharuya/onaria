# Apple 연결 해제와 회원탈퇴

Apple 연결 계정의 탈퇴/연결 해제는 앱에서 Apple 본인 확인을 다시 수행한 후 서버에 일회 authorization code와 ID token을 HTTPS 요청 body로 보낸다. 서버는 현재 ONARIA 회원에 연결된 Apple subject와 새 증명의 subject를 비교하고, 코드 교환 결과의 ID token도 같은 subject인지 별도로 검증한 다음 refresh token을 Apple `/auth/revoke`로 철회한다. 철회 성공 전 회원 DB를 변경하지 않는다. 회원탈퇴 성공 시 모든 연결 provider의 ONARIA 세션을 철회한다.

Android는 기존 Service ID challenge/nonce callback 경로를 사용한다. Apple code/JWT는 5분 proof 만료 내 서버 메모리에만 보관한다. Android intent에는 opaque proof만 전달하고 탈퇴 시 서버에서 실제 grant를 일회 소비한다. 재시작/만료/실패 후에는 Apple 본인 확인을 다시 수행한다. 토큰/코드는 파일이나 DB에 저장하지 않고 로그에 기록하지 않는다.

## 운영 설정 Gate

다음은 서버 환경에만 설정한다. 실제 값이나 `.p8` 내용을 저장소/채팅에 넣지 않는다.

- `ONARIA_APPLE_CLIENT_ID`: iOS 앱 식별자(기존 Apple 로그인 검증과 동일)
- `ONARIA_APPLE_SERVICE_ID`: Android 웹 인증 Service ID
- `ONARIA_APPLE_REDIRECT_URI`: 등록된 HTTPS Android callback URL
- `ONARIA_APPLE_TEAM_ID`: Apple Developer Team ID
- `ONARIA_APPLE_KEY_ID`: Sign in with Apple 키 ID
- `ONARIA_APPLE_PRIVATE_KEY_PATH`: 서버 밖에서 안전하게 준비한 `.p8`의 절대경로. 서버 서비스 계정 읽기 전용, 최소 권한. 키 내용 자체를 env/mobile/Git에 넣지 않는다.

키 누락/잘못된 키/Apple 통신 실패 시 503으로 실패하고 회원 데이터와 세션은 유지한다. 본인 확인 계정이 다르면 401로 실패하며 그 계정을 철회하지 않는다. 설정 없이도 탈퇴가 동작한다고 표시하면 안 된다.

## 실제 출시 검증

테스트용 Apple 계정으로 iOS 및 Android에서 가입/재로그인/Apple 연결 해제/회원탈퇴를 확인하고, Apple 승인 상태 철회와 모든 ONARIA 세션 무효화를 확인한다. 기존 실제 회원 데이터는 테스트에 사용하지 않는다. 기존 연결 회원도 저장된 Apple refresh token이 없어 새 본인 확인이 필요하다. Apple 재인증이 불가능한 사용자는 운영 개인정보 문의를 통한 삭제 요청 경로도 운영 주체의 실제 연락처에 맞추어 제공해야 한다.

Apple 근거: https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple
