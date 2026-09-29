# ONARIA 웹앱 로컬 검증 — 2026-09-29

기준 HEAD: `e8a47f81ab14d78372b93c6e4ab2a5250488c172` + 이번 웹앱 미커밋 변경.
사용자가 설정한 iOS Development Team과 기존 게임 회귀 테스트를 보존했다.
별도 Buddhist 저장소는 변경하지 않았다.

| 항목 | 결과 |
| --- | --- |
| 변경 전 홈/API/게임 테스트 | 9 PASS |
| Flutter 전체 테스트 | 127 PASS, 기존 1 SKIP |
| Flutter 정적 분석 | PASS, 기존 example/main.dart avoid_print 정보 4개 |
| Backend 전체 테스트 | 421 PASS, 실제 AI 호출 없음 |
| Release Web `/webapp/` 빌드 | PASS |
| iOS unsigned simulator compile | PASS |
| Chromium 1280×720 / WebKit 390×844 | 최종 전체 실행 10 PASS (1.8분) |
| JS 구문 / workflow YAML 구문 / git diff 공백 검사 | PASS |
| 변경 파일 및 웹 산출물 secret 패턴 검사 | 발견 0건, 모든 비밀값의 부재를 증명하는 검사는 아님 |
| 로컬 미리보기 HTTP | 200, loopback 서버 |
| GitHub Actions | NOT RUN — workflow 작성 및 로컬 구문 검증만 완료 |
| 공개 호스팅 / DNS / 운영 설정 변경 | NOT RUN — 사용자 승인 완료, 서버 연결 정보 필요 |
| Android/iPhone 실제 웹브라우저 / 홈 화면 추가 | NOT RUN — 브라우저 자동화가 실기기 검증을 대체하지 않음 |
| 실서버 정상 AI 왕복 | NOT RUN — CORS·인증 확인 전 production 호출 안 함 |

브라우저 최종 검증은 두 브라우저 전체 10개를 한 번에 실행해 통과했다.
자동화 초기에 Flutter의 메뉴 접근성 명칭, 편집기 교체, 지연 목록,
이동하는 별의 좌표 안정화 때문에 실패한 테스트를 수정했다. 앱에서는 웹 접근성
트리를 계속 유지하도록 보완했고, 동의 취소 후 입력 보존을 다시 확인했다.
대화 시작 버튼은 스크롤 후 전체 화면 접근성 레이어가 포인터를 전달하므로
DOM 가로채기 검사 없이 실제 포인터 클릭을 보내고 대화 입력창 노출을 검증한다.
최종 소스 Flutter 테스트도 127 PASS, 기존 1 SKIP으로 재확인했다.

## 브라우저 시나리오

1. 웹 메뉴/사용 안내, 회원가입 비노출, 알림 미지원 안내, 별 6개 완료 시 3→2 버튼,
   재시작.
2. AI 동의 취소 시 0회 전송 및 입력 보존 → 동의 후 계약에 맞는 로컬 합성 응답
   3회 → 기존 말씀 자산 → 작은 실천 → 카드 저장 → 새로고침 복원 → 상세 내용
   확인 → PNG 다운로드. OS 공유창 대신 share API 미지원 조건으로 다운로드
   fallback을 확인했다. 실제 SNS 전송은 하지 않았다.
3. API 503 시 실제 AI 답변을 받지 못했다는 안내.
4. 위기 입력은 동의창 없이 고정 긴급 지원, production API 요청 0회.
5. 초기화 스크립트 로딩 실패 시 다시 열기, scoped manifest, CacheStorage 및
   등록된 service worker 없음, 정적 서버의 API/비밀파일 경로 404.

모든 브라우저 테스트는 production API 요청을 가로챈다. 실제 사용자 기록이나
운영 DB를 사용하지 않는다. WebKit 작은 화면 검사는 실제 iPhone 터치·음성·
공유 시트·홈 화면 설치 검증을 포함하지 않는다.

## 공개 전에 남은 사항

- `https://onaria.ai.kr` Origin의 production API OPTIONS 응답에
  Access-Control-Allow-Origin이 없었다. CORS 및 실제 API 인증 요구 확인 필요.
- 운영 주체·문의처·보유기간·국외이전 등 개인정보처리방침 확정, NIV 등 배포 권한 확인.
- 실제 서버 설정에 맞는 정적 호스팅 경로/보안 헤더 검토, 정확한 SHA의 CI 성공,
  실제 기기 및 production 확인. 사용자 운영 배포 승인은 받았으나 이 Mac에는
  SSH config와 문서의 soul-bible-server 별칭이 없어 연결 정보를 기다린다.
- Web 빌드는 JS/CanvasKit이다. flutter_tts의 Wasm 호환성 및 기존 Cupertino
  글꼴 경고가 남는다. iOS compile에는 flutter_tts의 향후 SPM 지원 경고가 있다.

로컬 ZIP은 미리보기용이며 CI artifact가 아니다. 실행과 운영 변경안은
[`WEBAPP_DEPLOYMENT.md`](WEBAPP_DEPLOYMENT.md)를 따른다.
