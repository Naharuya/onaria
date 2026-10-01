# ONARIA Feature Architecture

목적: 기능별 구조와 의존성을 코드 변경 전에 이해하고, 회귀와 소스 유실을 줄인다.

## 필수 기록 항목
1. 기능 목적 / 사용자 가치
2. 사용자 흐름 (Entry → Action → Result)
3. UI 화면 및 Widget
4. State / Controller / Domain logic
5. Local storage / DB / API
6. 핵심 파일과 책임
7. 다른 기능과의 의존성
8. QA / Unit / Widget / E2E 테스트
9. Known failure modes (알려진 실패 유형)
10. 변경 전 확인해야 할 Invariants (깨지면 안 되는 조건)
11. Release / migration 주의사항
12. 마지막 검증일 / 기준 commit

## 개발 규칙
- 기능 수정 전 해당 문서를 읽는다.
- 새 기능은 구현과 함께 구조 문서를 만든다.
- 기존 기능의 구조가 바뀌면 같은 변경에서 문서도 갱신한다.
- 테스트 이름과 실제 파일을 연결해 기록한다.
- 삭제/대체 파일은 Recycle Manifest와 연결한다.
- 기능 간 공통 의존성은 별도 shared architecture 문서로 승격한다.
