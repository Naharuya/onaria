import 'common_emotion_examples.dart';

/// Volatile per-screen/session personalization. Stores only fixed topic IDs/counts.
class PersonalKeywordLearning {
  PersonalKeywordLearning({this.isCurrent});
  final bool Function()? isCurrent;
  bool enabled = true;
  bool get available {
    if (!(isCurrent?.call() ?? true)) {
      clear();
      return false;
    }
    return enabled;
  }

  final Map<String, int> _counts = {};
  final Set<String> _hidden = {};
  final Map<String, Set<String>> _emotions = {};
  static const aliases = <String, List<String>>{
    '업무': ['업무', '직장', '회사', '야근'],
    '학업': ['학업', '공부', '시험', '과제'],
    '가족': ['가족'],
    '친구': ['친구'],
    '관계': ['관계', '연락', '답장', '대화'],
    '휴식': ['휴식', '쉼', '쉬고', '쉬는'],
    '미래': ['미래', '진로', '앞날'],
    '비교': ['비교', '성과', '성취'],
    '일상': ['일상', '산책', '취미'],
    '도전': ['도전', '목표', '계획'],
    '감사': ['감사', '고마움'],
    '기대': ['기대', '설렘'],
  };
  static Set<String> keywords(String text) {
    final tokens =
        RegExp(r'[가-힣]+').allMatches(text).map((m) => m[0]!).toList();
    final result = <String>{};
    for (final entry in aliases.entries) {
      if (entry.value.any((word) => tokens.any((token) =>
          token == word ||
          RegExp('^$word((에서|에게서|한테서|에게|한테|께|으로|로|와|과|에|부터|까지)(는|도|만)?|은|는|이|가|을|를|도|만|만으로|때문에|하고|하는|하기|하며)\$')
              .hasMatch(token)))) {
        result.add(entry.key);
      }
    }
    return result;
  }

  void observe(String text,
      {required String emotion, required bool safe, bool fromExample = false}) {
    if (!available || !safe || fromExample || text.length > 2000) return;
    if (RegExp(r'아니|말고|않|관계없|정정|그게 아니라').hasMatch(text)) return;
    for (final key in keywords(text)) {
      if (_hidden.contains(key)) continue;
      _counts[key] = ((_counts[key] ?? 0) + 1).clamp(0, 99);
      (_emotions[key] ??= <String>{}).add(
          commonEmotionExamples.containsKey(emotion) ||
                  aliases.containsKey(emotion)
              ? emotion
              : '기타');
    }
  }

  List<String> get cards {
    if (!available) return const [];
    final keys = _counts.keys.where((key) => _counts[key]! >= 3).toList();
    keys.sort((a, b) => _counts[b]!.compareTo(_counts[a]!) != 0
        ? _counts[b]!.compareTo(_counts[a]!)
        : a.compareTo(b));
    return keys.take(12).toList(growable: false);
  }

  List<String> examples(String card) {
    if (!available) return const [];
    final topics = cards.where((topic) =>
        topic == card ||
        (_emotions[topic]?.contains(card) ?? false) ||
        (!commonEmotionExamples.containsKey(card) &&
            keywords(card).contains(topic)));
    return [
      for (final topic in topics) ...[
        '$topic 이야기에서 지금 마음에 남는 일을 나누고 싶어요.',
        '$topic 이야기를 어디서부터 시작할지 천천히 생각하고 싶어요.',
        '$topic 이야기를 하며 지금 필요한 도움을 찾아보고 싶어요.',
        '$topic 이야기 중 작은 일 하나부터 말하고 싶어요.',
        '$topic 이야기에 여러 마음이 함께 들어 있어요.',
        '$topic 이야기를 제 속도에 맞춰 이어가고 싶어요.',
      ]
    ];
  }

  void remove(String topic) {
    _counts.remove(topic);
    _emotions.remove(topic);
    _hidden.add(topic);
  }

  void clear() {
    _hidden.clear();
    _counts.clear();
    _emotions.clear();
  }

  void setEnabled(bool value) {
    enabled = value;
    if (!value) clear();
  }
}

/// Selected suggestions are excluded for the lifetime of this conversation.
class ConversationExampleDeck {
  final Set<String> _selected = {};
  void select(String value) {
    _selected.add(value);
  }

  bool wasSelected(String value) => _selected.contains(value);
  static const neutral = <String>[
    '아직 잘 모르겠어서 조금 더 생각해 보고 싶어요.',
    '한마디로 정리하기 어려워 천천히 이야기하고 싶어요.',
    '지금은 자세히 말하기보다 짧게 답하고 싶어요.',
    '여러 답이 함께 떠올라 하나씩 살펴보고 싶어요.',
    '제게 맞는 표현을 조금 더 찾아보고 싶어요.',
    '지금 떠오르는 답을 아직 말로 옮기기 어려워요.',
    '정답을 고르기보다 제 생각을 천천히 적고 싶어요.',
    '조금 망설여지지만 편한 만큼 이야기하고 싶어요.',
    '지금은 다른 표현으로 제 마음을 전하고 싶어요.',
    '생각을 정리할 시간이 조금 더 필요해요.',
    '바로 답하기보다 잠시 마음을 살펴보고 싶어요.',
    '제 생각이 바뀔 수도 있어서 천천히 답하고 싶어요.',
    '여러 느낌 중 무엇부터 말할지 생각하고 있어요.',
    '지금은 답을 정하지 않고 조금 더 알아보고 싶어요.',
    '한 번에 다 설명하지 않고 조금씩 나누고 싶어요.',
  ];
  List<String> next(
      {required String question,
      required Iterable<String> primary,
      required String emotion,
      Iterable<String> personal = const [],
      bool starting = false}) {
    final pool = <String>{
      ...primary,
      if (starting) ...personal,
      if (starting)
        ...commonEmotionExamples[emotion] ?? commonGenericSituationExamples,
      ..._extra(question),
      ...neutral,
    };
    return pool
        .where((text) => text.trim().isNotEmpty && !_selected.contains(text))
        .take(5)
        .toList(growable: false);
  }

  static List<String> _extra(String q) {
    if (RegExp(r'반가운 느낌과 버거운 느낌').hasMatch(q))
      return const [
        '반가움과 버거움이 함께 느껴져요.',
        '아직 어느 쪽에 가까운지 모르겠어요.',
        '처음에는 반가웠지만 지금은 다른 마음도 느껴져요.',
        '마음이 바뀌고 있어서 조금 더 살펴보고 싶어요.',
        '여러 느낌을 하나씩 나누어 이야기하고 싶어요.'
      ];
    if (RegExp(r'몸|신체').hasMatch(q))
      return const [
        '몸의 느낌을 잠시 살펴보고 싶어요.',
        '지금은 몸의 변화가 뚜렷하지 않아요.',
        '호흡과 어깨의 느낌부터 천천히 알아보고 싶어요.'
      ];
    if (RegExp(r'생각|의미|이유').hasMatch(q))
      return const [
        '제게 중요한 것이 무엇인지 생각하고 있어요.',
        '그 일을 어떻게 받아들였는지 돌아보고 싶어요.',
        '떠오른 생각을 한 가지씩 정리하고 싶어요.'
      ];
    if (RegExp(r'도움|필요|위로').hasMatch(q))
      return const [
        '판단 없이 제 이야기를 들어 주면 좋겠어요.',
        '지금은 혼자 정리할 시간을 갖고 싶어요.',
        '어떤 도움을 원하는지 함께 찾아보고 싶어요.'
      ];
    if (RegExp(r'행동|실천|한 가지|한 걸음|시작').hasMatch(q))
      return const [
        '지금 할 수 있는 일 하나를 작게 정하고 싶어요.',
        '오늘은 잠시 쉬는 시간을 정해 볼게요.',
        '서두르지 않고 제 속도로 시작하고 싶어요.'
      ];
    if (RegExp(r'마음에 남|기억에 남|순간|장면').hasMatch(q))
      return const [
        '그 순간의 분위기가 마음에 남아요.',
        '제가 잠시 멈추었던 순간이 기억에 남아요.',
        '아직 무엇이 가장 남았는지 살펴보고 있어요.'
      ];
    return const [];
  }
}
