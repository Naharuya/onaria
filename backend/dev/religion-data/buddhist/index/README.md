# Buddhist index — TEST_DATA_ONLY

Buddhist 개발용 검색 인덱스의 분리된 위치다. 현재 인덱스는 생성하지 않는다.

- Christian 인덱스와 DB를 참조·복사·변경하지 않는다.
- 자동 수집·임베딩·유료 API 호출·인덱스 생성 작업을 추가하지 않는다.
- 현재 Provider는 코드에 정의된 Mock만 검색하며 이 경로를 읽지 않는다.
- 향후 이 단계에서 생성할 인덱스에는 허용된 `TEST_DATA_ONLY` Mock만 포함할 수 있다.
- `BLOCKED_EXTERNAL_REVIEW` 자료는 인덱싱하거나 검색 결과로 반환하지 않는다.
