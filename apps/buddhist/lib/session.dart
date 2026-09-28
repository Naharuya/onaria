import 'package:onaria_buddhist_pack/onaria_buddhist_pack.dart';
import 'package:onaria_core/onaria_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

const noMatch = '검색된 테스트 자료가 없습니다. 경전 문구나 출처를 생성하지 않습니다.';

class BuddhistSession {
  BuddhistSession(this.provider, this.preferences) {
    savedIds.addAll((preferences.getStringList(storageKey) ?? [])
        .where((id) => provider.getById(id) != null)
        .toSet());
  }
  static const storageKey = 'onaria.buddhist.test_only.cards.v1';
  final BuddhistScriptureProvider provider;
  final SharedPreferences preferences;
  final List<String> savedIds = [];
  ConversationState _state = ConversationState.start(ReligionProfile.buddhist);
  ConversationState get state => _state;
  int get riskLevel => _state.riskLevel;
  String message = '';
  List<MockScripture> citations = const [];
  MockScripture? card;
  CheckInInput? get checkIn => _state.checkIn;
  bool get isCrisis => riskLevel > 0;

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
    message = localCrisisMessage(riskLevel);
    return true;
  }

  void respond(String input,
      {ReligionProfile requestedProfile = ReligionProfile.buddhist}) {
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
    final updated = {...savedIds, record.id}.toList();
    // Only provider IDs are persisted, never user messages or editable citations.
    if (!await preferences.setStringList(storageKey, updated)) {
      throw StateError('SAVE_FAILED');
    }
    savedIds
      ..clear()
      ..addAll(updated);
  }

  List<MockScripture> get savedCards => isCrisis
      ? const []
      : savedIds
          .map(provider.getById)
          .whereType<MockScripture>()
          .toList(growable: false);
}
