/// Five-factor, session-only context. Call accept only after the app safety gate.
class CarePersonalization {
  CarePersonalization({required this.emotion, required this.intensity});
  final String emotion;
  final int intensity;
  final _answers = <String>[];
  final _questions = <String>[];
  List<String> get answers => List.unmodifiable(_answers);
  String get situation {
    final corrected = _answers.reversed.where((a) => RegExp(r'사실은|정정|그게 아니라').hasMatch(a));
    if (corrected.isNotEmpty) return corrected.first;
    for (var i = 0; i < _answers.length; i++) {
      final answer = _answers[i];
      final question = _questions[i];
      final clarification = RegExp(r'여러 마음 중|반가운 느낌과 버거운 느낌').hasMatch(question)
          && (answer.length < 24 || RegExp(r'느낌에 가까워|여러 마음이 함께').hasMatch(answer))
          && !RegExp(r'오늘|어제|친구|가족|일이|업무|회사|생일|소식').hasMatch(answer);
      if (!clarification) return answer;
    }
    return '';
  }
  String get desiredHelp {
    var result = 'unspecified';
    for (final answer in _answers) {
      final clauses = answer
          .replaceAll('말고', '말고,')
          .replaceAll('싫고', '싫고,')
          .replaceAll('않고', '않고,')
          .split(RegExp(r'[,，.!?。]|하지만|대신'));
      for (final part in clauses) {
        final negative = RegExp(r'않|싫|아니|원치|말고').hasMatch(part);
        final explicit =
            RegExp(r'싶|필요|바라|원해|도와|주세요|해줘|들어줘|좋겠|부탁').hasMatch(part) ||
                RegExp(r'^\s*(쉼|휴식|위로|이해|정리|연결|함께|조언|경청|응원|격려|용기)\s*$')
                    .hasMatch(part);
        if (!negative && !explicit) continue;
        var choice = 'unspecified';
        if (RegExp(r'쉬|쉼|휴식|조용히|잠시 멈').hasMatch(part)) choice = 'rest';
        if (RegExp(r'위로|이해|알아주|함께|연락|이야기.*나누|마음.*전|들어|경청|응원|격려|용기')
            .hasMatch(part)) choice = 'connection';
        if (RegExp(r'정리|순서|한 가지|하나만|준비|해결|방법|조언|계획').hasMatch(part))
          choice = 'order';
        if (RegExp(r'누리|즐기|감사.*전|좋은.*기록').hasMatch(part)) choice = 'savor';
        if (negative) {
          if (result == choice) result = 'unspecified';
        } else if (choice != 'unspecified') {
          result = choice;
        }
      }
    }
    return result;
  }

  bool get positive => const {'감사','기쁨','행복','기대','감탄','평온',
    '감사해요','기뻐요','행복해요','기대돼요','감탄해요','평온해요'}.contains(emotion);
  bool get lowBurden => intensity >= 7 && !positive;
  String get topic {
    if (RegExp(r'업무|할 일|일이 많|바쁘|일이 겹').hasMatch(situation)) return 'workload';
    if (RegExp(r'서운|섭섭|잊었|잊은|친구|가족|연락|답장|관계').hasMatch(situation))
      return 'relationship';
    if (RegExp(r'비교|질투|성과|뒤처').hasMatch(situation)) return 'comparison';
    if (RegExp(r'미래|시험|내일|걱정|불확실').hasMatch(situation)) return 'uncertainty';
    return 'unspecified';
  }

  void accept(String answer, {String question = ''}) {
    if (_answers.length >= 5 || answer.trim().isEmpty) return;
    _answers
        .add(answer.trim().substring(0, answer.trim().length.clamp(0, 2000)));
    _questions.add(question);
  }

  bool get helpWasAsked =>
      _questions.any((q) => RegExp(r'필요|도움|위로|쉬고 싶|이야기하고 싶|바랐').hasMatch(q));
  String question(int turn) {
    if (turn == 0 || _answers.isEmpty) {
      return lowBurden ? '지금 마음에 남은 일을 짧게 이야기해 주실래요?' : '오늘 어떤 일이 마음에 남았나요?';
    }
    if (situation.isEmpty) return '그 마음과 관련해 어떤 일이 있었나요?';
    final candidates = <String>[
      if (desiredHelp != 'unspecified')
        switch (desiredHelp) {
          'rest' => '잠시 쉬기 위해 지금 덜어낼 수 있는 일은 무엇인가요?',
          'connection' => '마음을 나누기 위해 지금 바라는 작은 도움은 무엇인가요?',
          'order' => '먼저 해볼 수 있는 작은 한 가지는 무엇인가요?',
          _ => '이 좋은 마음을 어떻게 누리거나 나누고 싶나요?',
        },
      if (turn == 1 && desiredHelp == 'unspecified')
        positive && !RegExp(r'걱정|불안|서운|섭섭|슬프|힘들|잊었|잊은').hasMatch(situation)
            ? '그 순간이 나에게 소중했던 이유는 무엇인가요?'
            : switch (topic) {
                'workload' => '겹친 일 중 지금 가장 부담이 되는 것은 무엇인가요?',
                'relationship' => '그 순간 어떤 말이나 반응을 바랐나요?',
                'comparison' => '비교하는 마음 뒤에서 내가 중요하게 여기는 것은 무엇인가요?',
                'uncertainty' => '걱정 중 지금 확인할 수 있는 것은 무엇인가요?',
                _ => positive
                    ? '그 순간이 나에게 소중했던 이유는 무엇인가요?'
                    : '그때 어떤 마음이 가장 크게 느껴졌나요?',
              },
      if (desiredHelp == 'unspecified' && !helpWasAsked)
        lowBurden ? '지금은 짧게 이야기하고 싶나요, 잠시 쉬고 싶나요?' : '지금 나에게 필요한 작은 도움은 무엇인가요?',
      desiredHelp == 'unspecified'
          ? '지금 부담 없이 할 수 있는 아주 작은 일은 무엇인가요?'
          : '방금 정한 선택을 내 상황에 맞게 얼마나 작게 시작할 수 있을까요?',
      '이미 나눈 이야기에서 오늘 기억하고 싶은 것은 무엇인가요?',
    ];
    return candidates.firstWhere(
        (q) => !_questions.any((previous) => previous.endsWith(q)),
        orElse: () => '오늘의 마음을 한 단어로 남긴다면 무엇인가요?');
  }

  String bridge(String perspective) {
    final subject = switch (topic) {
      'workload' => '겹친 일의 부담',
      'relationship' => '관계에서 마음에 남은 일',
      'comparison' => '비교하며 느낀 마음',
      'uncertainty' => '앞일에 대한 걱정',
      _ => positive ? '소중했던 순간' : '지금의 마음',
    };
    final help = switch (desiredHelp) {
      'rest' => '쉬고 싶은 뜻',
      'connection' => '이해와 연결을 바라는 뜻',
      'order' => '차근차근 정리하고 싶은 뜻',
      'savor' => '좋은 마음을 누리고 싶은 뜻',
      _ => '아직 정하지 않은 필요',
    };
    return '$subject과 $help을 함께 살펴볼게요. ' +
        (lowBurden ? '짧게 답하거나 쉬어도 괜찮아요. ' : '') +
        perspective;
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'emotion': emotion,
        'intensity': intensity,
        'situation': situation,
        'desiredHelp': desiredHelp,
        'alreadyAnswered': List<String>.from(_answers),
        'askedQuestions': List<String>.from(_questions),
      };
  void clear() {
    _answers.clear();
    _questions.clear();
  }
}
