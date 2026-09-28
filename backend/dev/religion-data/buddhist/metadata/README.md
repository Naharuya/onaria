# Buddhist metadata — TEST_DATA_ONLY

자료 식별·출처·권리 정보의 개발 전용 디렉터리다. 실제 경전 자료 레코드는 없다. `source_candidates.json`은 기관·출처 URL의 수동 검토 목록이며 경전 데이터나 인용 근거가 아니다. 개발 Admin에서만 확인하고 Provider/검색 인덱스에는 연결하지 않는다.

향후 metadata에 필요한 필드:

`scripture_id`, `tradition`, `collection`, `title`, `chapter`, `section`,
`language`, `translator`, `source`, `source_url`, `license`, `copyright_status`,
`retrieved_at`, `version`, `themes`, `emotion_tags`.

확인하지 않은 경전명·장절·번역자·출처를 생성하지 않는다. Mock의 확인 불가능한 필드는
명확히 비워 두며, Mock 상태는 `TEST_DATA_ONLY`로 표시한다.

실제 자료의 라이선스를 확인하지 못하면 `copyright_status = BLOCKED_EXTERNAL_REVIEW`다.
해당 자료는 사용자 응답·검색 결과·마음카드·인덱스에 사용할 수 없다.
오래된 원전이라는 이유로 한국어 번역문을 Public Domain으로 판단하지 않는다.
번역 저작권은 별도로 검증해야 한다. 이 문서는 승인된 자료나 사용권 증명이 아니다.
