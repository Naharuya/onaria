# Buddhist 외부 출처 검토 목록

2026-09-28. 사용자가 자료를 확보할 때까지 테스트 개발에 참고할 공식 출처와 권리 안내 경로를 요청했다. 검색으로 기관과 권리 안내를 확인하고 **본문 없는 검토 목록**을 구현했다. 실제 경전 인용 근거나 허가된 데이터셋을 생성한 작업은 아니다.

## 확인 경로

| 후보 | 공식 경로 / 확인 근거 | 현재 판정 |
|---|---|---|
| 동국대 불교학술원 | [KABC](https://kabc.dongguk.edu/), [공식 기관 공지](https://abchome.dongguk.edu/sub/contMasterView?cateType=&clsType=%EC%95%8C%EB%A6%BC%EB%A7%88%EB%8B%B9_%EA%B3%B5%EC%A7%80%EC%82%AC%ED%95%AD&dateE=&dateS=&dateType=&id=3643&q=&qw=&sortField=&sortOrder=desc&used=Y&viewType=) | 공식 공지 검색 색인에서 주소 확인. 서비스 직접 열기는 시간초과. 한국어 번역 이용권한 미확인 |
| SuttaCentral Bilara | [공식 저장소 라이선스](https://github.com/suttacentral/bilara-data/blob/published/LICENSE.md) | 특정 범위의 Bilara 번역에 CC0 안내 확인. 사용할 개별 번역·판본·언어·번역자는 아직 선택/검증하지 않음 |
| CBETA | [공식 FAQ](https://cbeta.org/en/faq) | 자료별 조건과 권리자 확인 필요 안내. 앱 재사용 허가 미확인 |
| BDRC | [공식 접근 정책](https://www.bdrc.io/access-policies/) | 공식 정책 검색 색인 확인, 직접 접속 시간초과. 공개/제한 자료가 혼재하며 개별 권리 검토 필요 |

원전의 오래된 연대만으로 한국어 번역을 Public Domain으로 판단하지 않는다. 열람 가능 여부와 앱 내 저장·인용·재배포 허가는 별개다. 특정 제공처의 권리 안내를 모든 번역에 일괄 적용하지 않았다.

네이버 검색 자동 접근은 robots 제한, 구글 검색 페이지 직접 접근은 도구 오류로 결과를 읽지 못했다. 일반 웹 검색과 공식 페이지/공식 페이지 검색 색인을 사용했고 성공한 검색 엔진을 허위로 표시하지 않았다. Admin의 네이버/구글 링크는 사용자가 직접 여는 검색 바로가기이며 검색 결과를 확인한 증거나 경전 출처가 아니다.

## 적용 위치와 차단 경계

- 목록: `backend/dev/religion-data/buddhist/metadata/source_candidates.json`
- 검증: `backend/dev/religion-packs/buddhist/source_review.js`
- 읽기 전용 API: `/api/admin/source-review` (개발 세션 필수)
- 개발 Admin: **출처 검토 목록 확인** 버튼.
- 전 항목 `copyright_status=BLOCKED_EXTERNAL_REVIEW`, `ingest_allowed=false`.
- 기관명/URL/권리 검토 메모만 보관한다. 경전 전문·번역문·장절·번역자·가짜 문헌 식별자를 만들지 않았다.
- Provider 및 검색 인덱스는 이 목록을 로드하지 않는다. 목록 ID로 마음카드 생성 불가.
- 버튼 클릭으로 목록을 읽어도 외부 HTTP 요청이 발생하지 않는다. 외부 링크는 사용자가 직접 선택할 때만 열리며 referrer와 opener를 차단한다.
- 실제 앱 대화·검색·마음카드는 기존 TEST_DATA_ONLY Mock을 유지한다. Android APK, 맥미니 AI 동작, Christian 서비스는 변경하지 않았다.

## 검증 및 종료

변경 전 관련 10 PASS, 변경 후 Admin/Pack 11 PASS, 브라우저 E2E 6 PASS(360px overflow/접근성/외부 자동 요청 없음 포함), Christian Safety/API 계약 회귀 4 PASS. 실제 검색/카드에서 후보 목록 항목이 배제되는지 테스트했다. 경로·diff·커밋 대상 비밀정보 검사를 수행한다.

Android/iOS 빌드 및 실기기 설치 NOT RUN: 앱 변경 없음. 운영 API·DB·배포 NOT RUN: 사용자 금지 범위. CI/push NOT RUN: 사용자 요청으로 보류. 실제 경전 자동 수집·저장·AI 번역은 수행하지 않았다.

후속 자료 확보 시 기관 링크만으로 승인하지 말고 사용할 작품/판본/언어/번역자와 구체적 이용권한 근거를 검토한다. 미검증 자료의 앱 사용은 계속 차단한다.
