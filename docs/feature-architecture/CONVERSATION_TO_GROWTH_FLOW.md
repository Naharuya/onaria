# Feature: 마음대화 → 말씀 → 마음카드 → Cross Light → 성장기록

- Status: Baseline QA in progress
- Last verified: 2026-10-01
- Baseline commit: pending

## 1. 목적
사용자가 감정을 선택하고 세 번의 마음대화를 거쳐 말씀과 작은 실천을 선택하고, 마음카드를 저장한 뒤 Cross Light를 완료하면 성장기록으로 이어지는 핵심 여정.

## 2. 사용자 흐름
Check-in → Conversation(최대 3 core turns) → Verse Offer → Verse → Action → Mind Card → Save/Share → Cross Light(6 pieces) → Growth

## 3. UI 구조
- CheckInPage
- ConversationPage
- SharePreviewPage
- CrossLightPage / CrossLightSky
- GrowthPage / SavedCardsPage

## 4. 상태 / 도메인 로직
- ConversationMachine: 대화 단계 전환
- ConversationSession: turn/state
- CrossLightGame: 5초 간격, 6개 조각, complete 조건
- CrossLightPage: 완료 이벤트와 route result
- ConversationPage: Cross Light result + game.complete를 모두 확인한 뒤 Growth로 이동

## 5. 데이터 / 저장소 / API
- LlmApiClient / ProxyLlmApiClient
- VerseRepository
- MindCardStore
- 로컬 마음카드 저장 후 공유/게임 흐름

## 6. 핵심 파일과 책임
- lib/features/check_in_page.dart
- lib/features/conversation_page.dart
- lib/app/mind_card_store.dart
- lib/engagement/mini_games/cross_light/cross_light_game.dart
- lib/engagement/mini_games/cross_light/cross_light_sky.dart
- lib/engagement/mini_games/cross_light/cross_light_page.dart
- lib/features/growth_page.dart
- lib/features/saved_cards_page.dart

## 7. 의존 기능
Emotion Card, Verse, TTS/Speech, Share Preview, Engagement analytics, Growth records.

## 8. 테스트 맵
- test/conversation_examples_test.dart
- test/cross_light_page_test.dart
- test/cross_light_sky_test.dart
- test/cross_light_lifecycle_test.dart
- test/engagement_integration_test.dart
- test/emotion_card_store_test.dart
- test/responsive_layout_test.dart

## 9. 알려진 실패 유형
- Cross Light 6개 조각 완료 후 UI 완료 상태/버튼이 즉시 렌더링되지 않는 회귀: 2026-10-01 조사 중.
- 저장 실패/재시도 후 중복 카드 생성 방지 필요.
- route result=true만으로 Growth 이동 금지: game.complete도 반드시 true.
- 작은 화면 overflow와 Growth 하단 스크롤 접근성.

## 10. 변경 불가 조건 (Invariants)
- 핵심 대화는 최대 3회.
- 카드 저장 실패 시 Cross Light로 이동하지 않는다.
- 공유 재시도가 카드를 중복 저장하지 않는다.
- Cross Light는 실제 6개 입력 완료 전 Growth로 이동할 수 없다.
- Back/cancel은 Growth 완료로 취급하지 않는다.
- 기존 저장 카드를 임의 삭제하지 않는다.

## 11. Release / Migration 주의사항
Play 설치본 build 7에서 제공되던 기능을 기준으로 회귀 여부를 비교한다. Release Source Drift가 발견되면 버전 증가 전에 먼저 소스를 reconcile한다.

## 12. 변경 이력
- 2026-10-01: build 7 소스 회수 과정에서 기능 구조 문서화 시작.
