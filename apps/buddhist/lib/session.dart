import 'package:onaria_buddhist_pack/onaria_buddhist_pack.dart';
import 'package:onaria_core/onaria_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mind_card_store.dart';

const noMatch = '검색된 테스트 자료가 없습니다. 경전 문구나 출처를 생성하지 않습니다.';

class BuddhistSession {
  BuddhistSession(this.provider, this.preferences, {MindCardStore? cardStore})
      : _cardStore = cardStore ?? MindCardStore(preferences);
  static const storageKey = MindCardStore.legacyKey;
  final BuddhistScriptureProvider provider;
  final SharedPreferences preferences;
  final MindCardStore _cardStore;
  String? get storageNotice => _cardStore.loadFailed
      ? '저장 기록을 읽지 못했습니다. 기존 기록을 보호하기 위해 새 저장을 중단했습니다.'
      : null;
  List<String> get savedIds =>
      List.unmodifiable(savedDetails.map((r) => r.scripture.id));
  ConversationState _state = ConversationState.start(ReligionProfile.buddhist);
  ConversationState get state => _state;
  int get riskLevel => _state.riskLevel;
  String message = '';
  List<MockScripture> citations = const [];
  MockScripture? card;
  CheckInInput? get checkIn => _state.checkIn;
  bool get isCrisis => riskLevel > 0;

  bool _guided = false;
  bool get isGuided => _guided;
  ConversationPhase get phase => _state.phase;
  String? selectedAction;
  static const actions = [
    '잠시 쉬기',
    '물 한 잔 마시기',
    '주변 사람에게 안부 전하기',
    '지금은 선택하지 않기'
  ];

  void startConversation(CheckInInput input) {
    // Preserve any previous risk, including when starting again.
    if (!beginCheckIn(input)) return;
    _guided = true;
    selectedAction = null;
    _state = _state.atPhase(ConversationPhase.situation);
    message = '그 마음이 들었던 상황을 편한 만큼 이야기해 주세요.';
  }

  void reply(String input,
      {ReligionProfile requestedProfile = ReligionProfile.buddhist}) {
    late final ConversationState next;
    try {
      next = _state.acceptInput(input,
          requestedProfile: requestedProfile, nextPhase: phase);
    } on StateError {
      citations = const [];
      card = null;
      message = '';
      rethrow;
    }
    if (next.isCrisis) {
      _state = next;
      _showCrisis();
      return;
    }
    final trimmed = input.trim();
    if (trimmed.isEmpty ||
        trimmed.length > CheckInInput.maxCustomEmotionLength) {
      throw ArgumentError('INPUT_LENGTH');
    }
    if (!_guided) throw StateError('CONVERSATION_NOT_STARTED');
    final target = switch (phase) {
      ConversationPhase.situation => ConversationPhase.need,
      ConversationPhase.need => ConversationPhase.sourceOffer,
      ConversationPhase.sourceReflection => ConversationPhase.action,
      _ => throw StateError('INVALID_PHASE'),
    };
    _state = next.atPhase(target);
    message = switch (target) {
      ConversationPhase.need =>
        '지금 나에게 필요한 것은 무엇인가요? 쉼이나 누군가의 이해처럼 편하게 적어 주세요.',
      ConversationPhase.sourceOffer =>
        '마음을 돌아볼 합성 테스트 자료를 볼까요? 실제 경전이나 번역문은 아닙니다.',
      _ => '오늘 할 수 있는 작은 실천을 하나 골라 주세요. 선택하지 않아도 괜찮습니다.',
    };
  }

  void chooseSource(bool accepted, {String pendingInput = ''}) {
    if (_interceptPending(pendingInput)) return;
    _requirePhase(ConversationPhase.sourceOffer);
    citations = const [];
    card = null;
    if (!accepted) {
      _state = _state.atPhase(ConversationPhase.action);
      message = '자료를 보지 않아도 괜찮습니다. 오늘 할 수 있는 작은 실천을 골라 주세요.';
      return;
    }
    try {
      final query = checkIn!.customEmotion ?? checkIn!.emotion.label;
      final found = provider.search(query);
      for (final record in found) {
        provider.assertCitation(record.metadata);
      }
      citations = List.unmodifiable(found);
      _state = _state.atPhase(found.isEmpty
          ? ConversationPhase.action
          : ConversationPhase.sourceReflection);
      message = found.isEmpty
          ? '$noMatch\n자료 없이 작은 실천을 선택할 수 있습니다.'
          : '아래 합성 테스트 자료를 보고 어떤 생각이 드나요? 맞지 않는 부분을 적어도 괜찮습니다.';
    } catch (_) {
      // Remain at consent so the user can retry or continue without a source.
      citations = const [];
      message = '테스트 자료를 열지 못했습니다. 다시 시도하거나 자료 없이 계속해 주세요.';
    }
  }

  void chooseAction(String action, {String pendingInput = ''}) {
    if (_interceptPending(pendingInput)) return;
    _requirePhase(ConversationPhase.action);
    if (!actions.contains(action)) throw ArgumentError('UNKNOWN_ACTION');
    selectedAction = action;
    _state = _state.atPhase(ConversationPhase.summary);
    message =
        '오늘 알아차린 마음: ${checkIn!.emotion.label} · ${checkIn!.intensity}/10\n'
        '나의 선택: $action\n지금 돌아본 것만으로도 충분합니다. 자신의 속도로 마무리해 주세요.';
  }

  /// Used before card and navigation controls consume any pending editor text.
  bool allowPendingInput(String input) => !_interceptPending(input);

  bool _interceptPending(String input) {
    final assessed = _state.acceptInput(input,
        requestedProfile: ReligionProfile.buddhist, nextPhase: phase);
    if (!assessed.isCrisis) return false;
    _state = assessed;
    return _showCrisis();
  }

  void newCheckIn() {
    _requirePhase(ConversationPhase.summary);
    _guided = false;
    _state = _state.atPhase(ConversationPhase.emotion);
    citations = const [];
    card = null;
    selectedAction = null;
    message = '';
  }

  void _requirePhase(ConversationPhase expected) {
    if (isCrisis) throw StateError('SAFETY_FIRST');
    if (!_guided || phase != expected) throw StateError('INVALID_PHASE');
  }

  /// False means safety intercepted before conversation or retrieval starts.
  bool beginCheckIn(CheckInInput input) {
    _state = _state.beginCheckIn(input);
    citations = const [];
    card = null;
    message = '';
    return !_showCrisis();
  }

  bool _showCrisis() {
    if (!isCrisis) return false;
    citations = const [];
    card = null;
    selectedAction = null;
    message = localCrisisMessage(riskLevel);
    return true;
  }

  void respond(String input,
      {ReligionProfile requestedProfile = ReligionProfile.buddhist}) {
    if (_guided) {
      reply(input, requestedProfile: requestedProfile);
      return;
    }
    citations = const [];
    card = null;
    message = '';
    _state = _state.acceptInput(input, requestedProfile: requestedProfile);
    if (_showCrisis()) return;
    citations = provider.search(input);
    message = citations.isEmpty
        ? noMatch
        : '실제 경전이 아닌 화면 검증용 자료입니다. 원하시면 잠시 쉬어 가셔도 괜찮습니다.';
  }

  void makeCard(String id) {
    if (isCrisis) throw StateError('SAFETY_FIRST');
    final record = provider.getById(id);
    if (record == null || !citations.contains(record)) {
      throw StateError('UNSUPPORTED_SCRIPTURE');
    }
    provider.assertCitation(record.metadata);
    card = record;
  }

  Future<void> saveCard() async {
    if (isCrisis) throw StateError('SAFETY_FIRST');
    final record = card;
    if (record == null) throw StateError('NO_CARD');
    provider.assertCitation(record.metadata);
    await _cardStore.save(record.id);
  }

  List<SavedMindCard> get savedDetails {
    if (isCrisis) return const [];
    final result = <SavedMindCard>[];
    for (final reference in _cardStore.records) {
      final record = provider.getById(reference.scriptureId);
      if (record == null || record.copyrightStatus != 'TEST_DATA_ONLY') {
        continue;
      }
      try {
        provider.assertCitation(record.metadata);
        result.add(SavedMindCard._(record, reference.savedAt));
      } on StateError {/* Unverified references are never displayed. */}
    }
    return List.unmodifiable(result);
  }

  SavedMindCard? savedDetail(String id) {
    if (isCrisis) throw StateError('SAFETY_FIRST');
    for (final detail in savedDetails) {
      if (detail.scripture.id == id) return detail;
    }
    return null;
  }

  List<MockScripture> get savedCards =>
      List.unmodifiable(savedDetails.map((r) => r.scripture));
}

class SavedMindCard {
  const SavedMindCard._(this.scripture, this.savedAt);
  final MockScripture scripture;
  final DateTime? savedAt;
}
