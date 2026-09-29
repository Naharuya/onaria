# Android Store Signing Setup

ONARIA의 신규 Play 등록용 upload key를 로컬에서 생성하는 절차다.

## 원칙
- keystore와 비밀번호를 Git에 올리지 않는다.
- 기존 `com.example...` 앱의 데이터/서명 연속성은 요구하지 않는다.
- Play App Signing 사용을 전제로 upload key와 Google Play app signing key를 분리한다.
- 생성 후 keystore와 비밀번호를 별도 안전한 백업 위치에 보관한다.

## Mac 실행 예시

터미널에서 비밀번호 값을 화면에 남기고 싶지 않으면 직접 export하지 말고 안전한 로컬 셸 세션에서 입력한다.

```bash
cd /Users/ari/ari-server/projects/onaria

read -r -p "Key alias: " ONARIA_KEY_ALIAS
read -r -s -p "Store password: " ONARIA_STORE_PASSWORD; echo
read -r -s -p "Key password: " ONARIA_KEY_PASSWORD; echo

export ONARIA_KEY_ALIAS ONARIA_STORE_PASSWORD ONARIA_KEY_PASSWORD
bash scripts/setup-android-upload-key.sh
unset ONARIA_KEY_ALIAS ONARIA_STORE_PASSWORD ONARIA_KEY_PASSWORD
```

생성 파일:
- `android/onaria-upload.jks`
- `android/key.properties`

두 파일 모두 현재 .gitignore 규칙으로 Git에서 제외된다.

## 다음 검증
1. `flutter build appbundle --release --dart-define=ONARIA_API_BASE_URL=https://api.onaria.ai.kr`
2. AAB 생성 확인
3. package/applicationId = `com.onaria.app`
4. versionCode/versionName 확인
5. Play Console 내부 테스트에 업로드
6. Play App Signing 등록 후 업로드 인증서 지문 기록
7. assetlinks.json의 Android SHA-256 값을 실제 서명 지문과 맞춤

비밀번호·keystore 내용·private key는 이 문서나 채팅에 기록하지 않는다.
