import 'package:flutter/material.dart';
import 'package:onaria_buddhist_pack/onaria_buddhist_pack.dart';
import 'package:onaria_core/onaria_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session.dart';
import 'engagement.dart';
import 'obang_theme.dart';
import 'mac_ai_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final provider = await BuddhistScriptureProvider.load();
    final preferences = await SharedPreferences.getInstance();
    runApp(BuddhistApp(session: BuddhistSession(provider, preferences)));
  } catch (_) {
    runApp(const MaterialApp(
        home: Scaffold(
            body: SafeArea(
                child: Center(
      child: Text('테스트 자료를 열 수 없습니다. 앱을 다시 실행해 주세요.'),
    )))));
  }
}

class BuddhistApp extends StatelessWidget {
  const BuddhistApp({super.key, required this.session});
  final BuddhistSession session;
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ONARIA 불교 TEST',
        debugShowCheckedModeBanner: false,
        theme: ObangTheme.theme,
        home: BuddhistHome(session: session),
      );
}

class BuddhistHome extends StatefulWidget {
  const BuddhistHome({super.key, required this.session});
  final BuddhistSession session;
  @override
  State<BuddhistHome> createState() => _BuddhistHomeState();
}

class _BuddhistHomeState extends State<BuddhistHome>
    with WidgetsBindingObserver {
  late final BuddhistEngagement effects;
  String featureStatus = '';
  bool featureBusy = false;
  String? sharePreviewId;
  @override
  void initState() {
    super.initState();
    effects = BuddhistEngagement(widget.session);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) effects.stopSpeech();
  }

  Future<void> runFeature(
      Future<bool> Function() operation, String success) async {
    if (!session.allowPendingInput(input.text)) {
      setState(() {
        input.clear();
        sharePreviewId = null;
        featureStatus = '';
      });
      return;
    }
    setState(() {
      featureBusy = true;
      featureStatus = '';
    });
    try {
      final ok = await operation();
      if (mounted && !session.isCrisis) {
        setState(() {
          featureStatus = ok
              ? success
              : '기기 설정이나 권한을 확인해 주세요. 오프라인 한국어 음성이 없으면 읽기를 사용할 수 없습니다.';
        });
      }
    } catch (_) {
      if (mounted && !session.isCrisis) {
        setState(() {
          featureStatus = '기기 기능을 실행하지 못했습니다. 다시 시도해 주세요.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          featureBusy = false;
        });
      }
    }
  }

  final input = TextEditingController();
  EmotionType emotion = EmotionType.anxiety;
  double intensity = 5;
  String? inputError;
  int tab = 0;
  bool saving = false;
  String saveStatus = '';
  String? selectedSavedId;
  BuddhistSession get session => widget.session;
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    session.cancelAiReply();
    effects.dispose();
    input.dispose();
    super.dispose();
  }

  Widget panel(List<Widget> children) => Card(
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ));
  Widget source(MockScripture record, {bool button = false}) => panel([
        Text(record.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(record.text),
        const SizedBox(height: 12),
        Text(record.source),
        const Text('실제 경전·번역문이 아닌 합성 테스트 자료'),
        if (button)
          OutlinedButton(
              onPressed: () => setState(() {
                    if (!session.allowPendingInput(input.text)) {
                      input.clear();
                      return;
                    }
                    session.makeCard(record.id);
                    saveStatus = '';
                  }),
              child: const Text('마음카드 만들기')),
      ]);

  List<Widget> conversation() => [
        if (!session.isGuided && !session.isCrisis) ...[
          const Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: ObangSymbol())),
          const Text('모든 마음은 저마다의 길이 있습니다',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, letterSpacing: 1.2, height: 1.6)),
          const SizedBox(height: 6),
          const Text('EVERY HEART HAS ITS OWN WAY',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: ObangTheme.blue, fontSize: 9, letterSpacing: 2)),
          const SizedBox(height: 24),
          Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.surfaceContainer
                      ]),
                  border: Border.all(color: ObangTheme.line),
                  borderRadius: BorderRadius.circular(18)),
              child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('매일 3분 마음대화',
                        style: TextStyle(
                            color: ObangTheme.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                    SizedBox(height: 12),
                    Text('오늘 마음은\n어떤가요?',
                        style: TextStyle(
                            color: ObangTheme.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.15)),
                    SizedBox(height: 12),
                    Text('판단하지 않고, 천천히 마음을 살펴보는 시간입니다.',
                        style: TextStyle(
                            color: ObangTheme.white,
                            fontSize: 14,
                            height: 1.5)),
                  ])),
          const SizedBox(height: 18),
        ],
        if (!session.isGuided || session.isCrisis)
          panel([
            Text('오늘의 마음', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, constraints) {
              final columns =
                  MediaQuery.textScalerOf(context).scale(14) > 20 ? 2 : 3;
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(spacing: 10, runSpacing: 10, children: [
                for (final value in EmotionType.values)
                  SizedBox(
                      width: width,
                      child: ChoiceChip(
                        showCheckmark: false,
                        backgroundColor: Color.alphaBlend(
                            ObangEmotionMark.edge(value.index)
                                .withValues(alpha: .045),
                            ObangTheme.black),
                        selectedColor: Color.alphaBlend(
                            ObangEmotionMark.edge(value.index)
                                .withValues(alpha: .18),
                            ObangTheme.black),
                        side: BorderSide(
                            color: ObangEmotionMark.edge(value.index)
                                .withValues(alpha: emotion == value ? .9 : .28),
                            width: emotion == value ? 1.5 : 1),
                        label: SizedBox(
                            width: width,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(alignment: Alignment.center, children: [
                                    SizedBox(
                                        width: width - 20,
                                        child: Center(
                                            child: ObangEmotionMark(
                                                index: value.index,
                                                selected: emotion == value))),
                                    if (emotion == value)
                                      const Positioned(
                                          right: 0,
                                          top: 0,
                                          child: ExcludeSemantics(
                                              child: Icon(Icons.check_circle,
                                                  size: 16,
                                                  color: ObangTheme.yellow))),
                                  ]),
                                  const SizedBox(height: 10),
                                  Text(value.label,
                                      textAlign: TextAlign.center),
                                ])),
                        selected: emotion == value,
                        onSelected: session.isCrisis
                            ? null
                            : (_) => setState(() {
                                  emotion = value;
                                }),
                      )),
              ]);
            }),
            const SizedBox(height: 12),
            Text('감정 강도 · ${intensity.round()}/10'),
            Slider(
              key: const Key('emotion-intensity'),
              min: 1,
              max: 10,
              divisions: 9,
              value: intensity,
              label: '${intensity.round()}/10',
              semanticFormatterCallback: (value) => '${value.round()} / 10',
              onChanged: session.isCrisis
                  ? null
                  : (value) => setState(() {
                        intensity = value;
                      }),
            ),
            TextField(
                controller: input,
                maxLength: CheckInInput.maxCustomEmotionLength,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                    labelText: '어떤 마음이 드시나요?',
                    hintText: '지금의 마음이나 테스트 키워드를 적어 주세요.',
                    errorText: inputError,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)))),
            FilledButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    inputError = null;
                    try {
                      final checkIn = CheckInInput(
                          emotion: emotion,
                          intensity: intensity.round(),
                          customEmotion: input.text);
                      session.startConversation(checkIn);
                      input.clear();
                    } on ArgumentError {
                      inputError = '직접 입력한 마음을 2,000자 이내로 적어 주세요.';
                    }
                    saveStatus = '';
                  });
                },
                child: const Text('마음 살펴보기')),
          ]),
        if (session.message.isNotEmpty)
          panel([
            if (session.checkIn != null)
              Text(
                  '선택한 마음: ${session.checkIn!.emotion.label} · ${session.checkIn!.intensity}/10'),
            Semantics(
                liveRegion: true,
                child: Text(session.message,
                    style: Theme.of(context).textTheme.bodyLarge)),
            if (session.isCrisis)
              const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('지금 안전한 곳에 계신가요? 곁에 함께 있어 줄 사람에게 연락할 수 있나요?')),
          ]),
        if (session.isGuided && !session.isCrisis) guidedControls(),
        if (!session.isCrisis)
          ...session.citations.map((record) => source(record, button: true)),
        if (!session.isCrisis && session.card != null)
          panel([
            Text('TEST_DATA_ONLY 마음카드',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(session.card!.text),
            Text(session.card!.source),
            Text('이용 조건: ${session.card!.license}'),
            const Text('저장되는 정보: 테스트 자료 ID와 저장 시각. 대화 내용은 저장하지 않습니다.'),
            if (session.storageNotice != null) Text(session.storageNotice!),
            FilledButton(
                onPressed: saving || session.storageNotice != null
                    ? null
                    : () async {
                        var allowed = false;
                        setState(() {
                          allowed = session.allowPendingInput(input.text);
                          if (!allowed) input.clear();
                          saving = allowed;
                        });
                        if (!allowed) return;
                        try {
                          await session.saveCard();
                          if (mounted && !session.isCrisis) {
                            setState(() {
                              saveStatus = '이 기기에 저장했습니다.';
                            });
                          }
                        } catch (_) {
                          if (mounted && !session.isCrisis) {
                            setState(() {
                              saveStatus = '저장하지 못했습니다. 다시 시도해 주세요.';
                            });
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              saving = false;
                            });
                          }
                        }
                      },
                child: const Text('마음카드 저장')),
            if (saveStatus.isNotEmpty) Text(saveStatus),
          ]),
      ];

  Widget guidedControls() => panel([
        Text(
            switch (session.phase) {
              ConversationPhase.situation => '1 · 상황 살펴보기',
              ConversationPhase.need => '2 · 필요한 것 알아차리기',
              ConversationPhase.sourceOffer => '3 · 자료 보기 선택',
              ConversationPhase.sourceReflection => '4 · 돌아보기',
              ConversationPhase.action => '5 · 작은 실천',
              _ => '6 · 마무리',
            },
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (session.aiPending) const Text('맥미니 AI가 안내를 고르고 있습니다…'),
        if (MacAiClient.enabled && session.lastReplyUsedFallback)
          const Text('AI 연결을 사용할 수 없어 기본 안내로 이어갑니다.'),
        if (session.phase != ConversationPhase.summary) ...[
          TextField(
            controller: input,
            maxLength: CheckInInput.maxCustomEmotionLength,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: '이어서 이야기하기',
              errorText: inputError,
              border: const OutlineInputBorder(),
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              FocusScope.of(context).unfocus();
              final text = input.text;
              setState(() {
                inputError = null;
              });
              try {
                if (MacAiClient.enabled) {
                  final pending =
                      session.replyWithMacAi(text, factory: MacAiClient.new);
                  setState(() {});
                  await pending;
                } else {
                  session.reply(text);
                }
                if (mounted) {
                  setState(() {
                    if (input.text == text) input.clear();
                    saveStatus = '';
                  });
                }
              } on ArgumentError {
                if (mounted) {
                  setState(() {
                    inputError = '1~2,000자 이내로 적어 주세요.';
                  });
                }
              } on StateError {
                if (mounted) {
                  setState(() {
                    inputError = session.aiPending
                        ? '답변을 기다리고 있습니다. 위험한 상황이라면 바로 입력해 주세요.'
                        : '아래 선택 버튼으로 계속해 주세요.';
                  });
                }
              }
            },
            child: const Text('이야기 보내기'),
          ),
        ],
        if (session.phase == ConversationPhase.sourceOffer) ...[
          FilledButton(
            onPressed: () => setState(() {
              session.chooseSource(true, pendingInput: input.text);
              inputError = null;
              input.clear();
            }),
            child: const Text('테스트 자료 보기'),
          ),
          TextButton(
            onPressed: () => setState(() {
              session.chooseSource(false, pendingInput: input.text);
              inputError = null;
              input.clear();
            }),
            child: const Text('자료 없이 계속하기'),
          ),
        ],
        if (session.phase == ConversationPhase.action)
          ...BuddhistSession.actions.map((action) => OutlinedButton(
                onPressed: () => setState(() {
                  session.chooseAction(action, pendingInput: input.text);
                  inputError = null;
                  input.clear();
                }),
                child: Text(action),
              )),
        if (session.phase == ConversationPhase.summary) ...[
          const Text('대화 내용은 저장하지 않습니다. 마음카드는 별도로 저장할 수 있습니다.'),
          TextButton(
              onPressed: () => setState(() {
                    session.newCheckIn();
                    input.clear();
                    inputError = null;
                    saveStatus = '';
                  }),
              child: const Text('새 마음 살펴보기')),
        ],
      ]);

  String savedDate(DateTime? date) => date == null
      ? '저장 시각 정보 없음 · 이전 버전 기록'
      : '저장 시각: ${date.toLocal().toIso8601String().replaceFirst('T', ' ').split('.').first}';

  List<Widget> saved() {
    if (session.isCrisis) {
      return [
        panel([Text(session.message)])
      ];
    }
    final records = session.savedDetails;
    final growth = GrowthSnapshot(session, DateTime.now());
    final detail =
        selectedSavedId == null ? null : session.savedDetail(selectedSavedId!);
    return [
      Text('나의 작은 쉼', style: Theme.of(context).textTheme.headlineMedium),
      if (session.storageNotice != null) panel([Text(session.storageNotice!)]),
      if (selectedSavedId != null) ...[
        TextButton(
            onPressed: () => setState(() => selectedSavedId = null),
            child: const Text('목록으로 돌아가기')),
        if (detail == null)
          panel([const Text('확인할 수 없는 테스트 자료입니다. 인용을 표시하지 않습니다.')])
        else ...[
          Text('마음카드 상세', style: Theme.of(context).textTheme.titleLarge),
          source(detail.scripture),
          panel([
            OutlinedButton(
                onPressed: featureBusy
                    ? null
                    : () => setState(() {
                          if (!session.allowPendingInput(input.text)) {
                            input.clear();
                            return;
                          }
                          sharePreviewId = detail.scripture.id;
                        }),
                child: const Text('공유 내용 미리보기')),
            if (sharePreviewId == detail.scripture.id) ...[
              SelectableText(effects.preview(detail.scripture.id)),
              const Text('공유되는 내용은 위 테스트 자료뿐입니다. 대화 내용과 계정 정보는 포함하지 않습니다.'),
              FilledButton(
                  onPressed: featureBusy
                      ? null
                      : () => runFeature(
                          () => effects.share(detail.scripture.id),
                          '공유 앱 선택 화면을 열었습니다. 전송 여부는 선택한 앱에서 확인해 주세요.'),
                  child: const Text('공유 앱 선택')),
            ],
            OutlinedButton(
                onPressed: featureBusy
                    ? null
                    : () => runFeature(() => effects.speak(detail.scripture.id),
                        '기기 내 음성 읽기를 시작했습니다.'),
                child: const Text('오프라인 음성으로 읽기')),
            TextButton(
                onPressed: () =>
                    runFeature(effects.stopSpeech, '음성 읽기를 중단했습니다.'),
                child: const Text('읽기 중단')),
            if (featureStatus.isNotEmpty) Text(featureStatus),
          ]),
          panel([
            Text(savedDate(detail.savedAt)),
            Text('이용 조건: ${detail.scripture.license}'),
            Text('권리 상태: ${detail.scripture.copyrightStatus}'),
            const Text('본문과 출처는 앱의 검증된 테스트 자료에서 확인합니다.'),
          ]),
        ],
      ] else ...[
        panel([
          Text('저장한 테스트 마음카드 ${records.length}개'),
          const Text('자신의 속도로 돌아보세요. 저장 기록은 이 앱 안에만 남습니다.'),
          if (records.isEmpty && session.storageNotice == null)
            const Text('아직 저장한 마음카드가 없습니다. 마음 화면에서 테스트 자료를 보고 카드를 저장해 보세요.'),
        ]),
        panel([
          Text('최근 7일 저장한 카드 ${growth.total}개'),
          const Text('저장 시각이 있는 카드만 집계합니다. 마음의 좋고 나쁨을 평가하는 점수가 아닙니다.'),
          for (final day in growth.days.entries)
            Text('${day.key.month}/${day.key.day} · ${day.value}개'),
        ]),
        panel([
          const Text('작은 쉼 알림 · 직접 켰을 때 한 번만 알립니다.'),
          const Text(
              '알림에는 대화나 경전 문구가 없습니다. 기기 절전 설정에 따라 늦어질 수 있으며 재부팅 후 다시 설정해 주세요.'),
          OutlinedButton(
              onPressed: featureBusy
                  ? null
                  : () => runFeature(
                      () => effects.reminder(1), '1분 뒤 쉼 알림을 요청했습니다.'),
              child: const Text('1분 뒤 알림 테스트')),
          OutlinedButton(
              onPressed: featureBusy
                  ? null
                  : () => runFeature(
                      () => effects.reminder(1440), '내일 이맘때 쉼 알림을 요청했습니다.'),
              child: const Text('내일 쉼 알림')),
          TextButton(
              onPressed: () =>
                  runFeature(effects.cancelReminder, '예약한 쉼 알림을 취소했습니다.'),
              child: const Text('알림 취소')),
          if (featureStatus.isNotEmpty) Text(featureStatus),
        ]),
        for (final record in records)
          panel([
            Text(record.scripture.title,
                style: Theme.of(context).textTheme.titleMedium),
            Text(savedDate(record.savedAt)),
            const Text('TEST_DATA_ONLY · 합성 테스트 자료'),
            OutlinedButton(
              key: ValueKey('open-${record.scripture.id}'),
              onPressed: () => setState(() {
                if (!session.allowPendingInput(input.text)) {
                  input.clear();
                  return;
                }
                selectedSavedId = record.scripture.id;
              }),
              child: const Text('카드 자세히 보기'),
            ),
          ]),
      ],
    ];
  }

  List<Widget> admin() => [
        Text('개발 상태', style: Theme.of(context).textTheme.headlineMedium),
        panel([
          Text(
              '현재 세션의 저장 가능 상태: ${session.storageNotice == null ? '정상' : '기록 보호 중'}'),
          Text(
              '최근 로컬 응답 복구: ${session.lastReplyUsedFallback ? '고정 안내 사용' : '정상'}'),
          const Text('대화 원문·계정·키 값은 진단에 표시하지 않습니다.'),
        ]),
        panel([
          Text('TEST_DATA_ONLY · 읽기 전용'),
          Text('Religion Profile: buddhist'),
          Text('실제 경전: 0개 / 합성 문장: 2개'),
          Text(MacAiClient.enabled
              ? '맥미니 AI · USB 개발 연결 / 클라우드 호출 없음'
              : '모델 호출: 0 / 외부 API 호출: 0'),
          Text('외부 자료: BLOCKED_EXTERNAL_REVIEW'),
          Text('자료 가져오기 및 승인 기능: 비활성'),
          Text('번역자의 저작권은 원전과 별도로 검증해야 합니다.'),
        ]),
      ];

  @override
  Widget build(BuildContext context) => ObangSky(
          child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('onaria · 불교 TEST',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1)),
          bottom: const PreferredSize(
              preferredSize: Size.fromHeight(4), child: ObangBand()),
        ),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: SingleChildScrollView(
                        key: ValueKey('$tab:$selectedSavedId'),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                  padding: const EdgeInsets.all(14),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                      color: const Color(0xff302B25),
                                      border: const Border(
                                          left: BorderSide(
                                              color: ObangTheme.red, width: 3)),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text(MacAiClient.enabled
                                      ? 'TEST_DATA_ONLY · 맥미니 AI\n대화 입력과 최근 두 답변을 USB로 연결한 맥에서 처리합니다. 경전은 합성 자료입니다.'
                                      : 'TEST_DATA_ONLY\n실제 경전이 아닌 합성 자료로 동작하는 오프라인 개발 앱입니다.')),
                              ...switch (tab) {
                                0 => conversation(),
                                1 => saved(),
                                _ => admin()
                              },
                            ]))))),
        bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (value) => setState(() {
                  if (!session.allowPendingInput(input.text)) input.clear();
                  selectedSavedId = null;
                  sharePreviewId = null;
                  featureStatus = '';
                  session.cancelAiReply();
                  effects.stopSpeech();
                  tab = value;
                }),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.spa_outlined), label: '마음'),
              NavigationDestination(
                  icon: Icon(Icons.bookmark_border), label: '저장·성장'),
              NavigationDestination(
                  icon: Icon(Icons.info_outline), label: '개발 상태'),
            ]),
      ));
}
