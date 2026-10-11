# ONARIA 맥미니 에이전트 구성

총괄 1개, 전문 5개, 스케줄 담당 1개의 저장된 Codex 역할이다.
프로젝트별 `.codex/agents/*.toml` 설정이므로 다른 프로젝트에는 적용하지 않는다.
설정 생성은 7개의 AI 프로세스가 계속 실행 중이라는 뜻이 아니다.
모델과 로그인은 기존 Codex 설정을 상속하며 API key를 추가하지 않는다.

| 역할 | 이름 |
| --- | --- |
| 총괄 | coordinator |
| Flutter·실기기 | flutter_device |
| 백엔드·인증 | backend_auth |
| 서버·배포 | server_deploy |
| QA·보안 | qa_security |
| 웹·관리자 | web_admin |
| 스케줄 | scheduler |

설정 확인:

```sh
cd /Users/ari/ARI/projects/onaria
python3 scripts/onaria-agent.py --check
```

작업 시작:

```sh
python3 scripts/onaria-agent.py coordinator 'ONARIA 미완료 작업을 확인하고 담당 역할에 배분해줘'
python3 scripts/onaria-agent.py scheduler '대기 작업과 선행 조건을 확인해줘'
```

Codex에서 프로젝트를 다시 열고 총괄에게 전문 역할을 명시해 요청할 수도 있다.
동시 스레드는 프로젝트 설정에서 4개로 제한한다. 같은 파일이나 실기기를 동시에
변경하지 않고, 구현 담당과 독립 QA 담당의 결과를 총괄이 통합한다.

스케줄 연결 정보와 ONARIA 대기 항목은 `.codex/onaria-schedule.json`에 저장한다.
전체 HTML 파일 분배와 실제 예약 전달은 `/Users/ari/ARI/agents/execution-engine`의
전용 `com.ari.agent-dispatch` 서비스가 수행한다. 15분 전달, 수정 후 20분 검증,
복구 최대 2회이며 전체 점검·ONARIA만 수정 권한을 적용한다.
전역 실행기에서 같은 7개 역할 이름을 재사용하며 문서 점검은 읽기 전용으로 수행한다.
계정 선택/동의, 기기 재로그인 결과, runner 등록 승인은 실제 답변이 있어야 해제한다.

운영 점검 담당은 읽기 전용이다. 배포가 승인되면 총괄이 검증된 CI artifact와
기존 데이터 보존 배포 스크립트를 사용한다. 비밀값·개인키·회원 원문 데이터는
에이전트 설정이나 일정 파일에 저장하지 않는다.

공식 형식: https://learn.chatgpt.com/docs/agent-configuration/subagents
