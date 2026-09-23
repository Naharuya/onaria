import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/onaria_emblem.dart';
import '../app/app_theme.dart';
import '../app/space_scaffold.dart';
import '../onaria.dart';
import '../app/mind_card_store.dart';
import '../app/emotion_card_store.dart';
import 'conversation_page.dart';
import 'saved_cards_page.dart';
import 'growth_page.dart';
import 'signup_page.dart';
import '../engagement/engagement_page.dart';
import '../engagement/journey/journey_page.dart';
import '../engagement/mini_games/cross_light/cross_light_page.dart';
import '../engagement/notifications/notification_settings_page.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _EmotionCardEntry {
  const _EmotionCardEntry({
    required this.label,
    required this.icon,
    required this.count,
    this.emotion,
    this.customKeyword,
    this.originalIndex = 0,
  });

  final String label;
  final String icon;
  final int count;
  final EmotionType? emotion;
  final String? customKeyword;
  final int originalIndex;
}

class _CheckInPageState extends State<CheckInPage> {
  EmotionType? _emotion;
  bool _otherEmotion = false;
  final _customEmotion = TextEditingController();
  double _intensity = 5;
  final _dailyUsageStore = DailyUsageStore();
  final _emotionCardStore = EmotionCardStore();
  EmotionCardStats _emotionStats =
      const EmotionCardStats(presetCounts: {}, customKeywordCounts: {});
  String? _promotedKeyword;
  int _dailyUsageCount = 0;
  bool _loadingUsage = true;
  bool _loadingEmotionCards = true;
  bool _startingConversation = false;
  String _versionLabel = '버전 확인 중';
  String _versionOnly = '';
  final _scrollController = ScrollController();

  static const _icons = <EmotionType, String>{
    EmotionType.anxiety: '🌊',
    EmotionType.loneliness: '🌙',
    EmotionType.exhaustion: '🍂',
    EmotionType.anger: '🔥',
    EmotionType.sadness: '🌧️',
    EmotionType.complexity: '🫧',
    EmotionType.gratitude: '🌿',
    EmotionType.joy: '☀️',
    EmotionType.fear: '🌑',
    EmotionType.disgust: '🌵',
    EmotionType.surprise: '⚡',
    EmotionType.happiness: '🌈',
    EmotionType.anticipation: '🎈',
    EmotionType.admiration: '🎆',
    EmotionType.overwhelmed: '🌋',
    EmotionType.jealousy: '🍏',
  };

  List<_EmotionCardEntry> get _emotionCards {
    final cards = <_EmotionCardEntry>[
      for (var i = 0; i < EmotionType.values.length; i++)
        _EmotionCardEntry(
          label: EmotionType.values[i].label,
          icon: _icons[EmotionType.values[i]]!,
          count: _emotionStats.presetCount(EmotionType.values[i]),
          emotion: EmotionType.values[i],
          originalIndex: i,
        ),
      for (final item in _emotionStats.popularCustomKeywords())
        _EmotionCardEntry(
          label: item.key,
          icon: '✨',
          count: item.value,
          customKeyword: item.key,
          originalIndex: EmotionType.values.length,
        ),
    ];
    cards.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.originalIndex.compareTo(b.originalIndex);
    });
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return SpaceScaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              children: [
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32, height: 32,
                      color: AppTheme.of(context).sage,
                      child: Icon(Icons.auto_awesome, size: 23, color: AppTheme.of(context).green),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('onaria', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, letterSpacing: 4)),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.menu, color: AppTheme.of(context).green, size: 24),
                    tooltip: '메뉴',
                    onSelected: (value) {
                      if (value == 'growth') {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GrowthPage()));
                      } else if (value == 'saved_cards') {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedCardsPage()));
                      } else if (value == 'signup') {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpPage()));
                      } else if (value == 'engagement') {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EngagementPage()));
                      } else if (value == 'journey') {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JourneyPage()));
                      } else if (value == 'cross_light') {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CrossLightPage()));
                      } else if (value == 'reminders') {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsPage()));
                      } else if (value == 'privacy') {
                        _openLegalUrl('/privacy');
                      } else if (value == 'privacy_transfer') {
                        _openLegalUrl('/privacy');
                      } else if (value == 'terms') {
                        _openLegalUrl('/terms');
                      } else if (value == 'licenses') {
                        showLicensePage(
                          context: context,
                          applicationName: 'ONARIA',
                          applicationVersion: _versionOnly,
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'growth', child: Text('작은 성장 기록')),
                      PopupMenuItem(value: 'journey', child: Text('7일 마음의 여정')),
                      PopupMenuItem(value: 'engagement', child: Text('말씀과 작은 기록')),
                      PopupMenuItem(value: 'cross_light', child: Text('십자가 미니게임')),
                      PopupMenuItem(value: 'reminders', child: Text('알림 설정')),
                      PopupMenuItem<String>(
                        value: 'signup',
                        child: Row(children: [
                          Icon(Icons.person_add_outlined),
                          SizedBox(width: 12),
                          Text('회원가입'),
                        ]),
                      ),
                      const PopupMenuItem<String>(
                        value: 'saved_cards',
                        child: Row(children: [
                          Icon(Icons.bookmarks_outlined),
                          SizedBox(width: 12),
                          Text('저장된 카드'),
                        ]),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'privacy',
                        child: Row(children: [
                          Icon(Icons.privacy_tip_outlined),
                          SizedBox(width: 12),
                          Text('개인정보 처리방침'),
                        ]),
                      ),
                      const PopupMenuItem<String>(
                        value: 'privacy_transfer',
                        child: Row(children: [
                          Icon(Icons.public_outlined),
                          SizedBox(width: 12),
                          Expanded(child: Text('개인정보 수집·이용 / 국외이전 현황')),
                        ]),
                      ),
                      const PopupMenuItem<String>(
                        value: 'terms',
                        child: Row(children: [
                          Icon(Icons.description_outlined),
                          SizedBox(width: 12),
                          Text('서비스 이용약관'),
                        ]),
                      ),
                      const PopupMenuItem<String>(
                        value: 'licenses',
                        child: Row(children: [
                          Icon(Icons.code_outlined),
                          SizedBox(width: 12),
                          Text('오픈소스 라이선스'),
                        ]),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        enabled: false,
                        value: 'version',
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            _versionLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 16),
                const Center(child: OnariaEmblem()),
                Text('모든 마음은 저마다의 길이 있습니다', textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.of(context).ink, fontSize: 14, letterSpacing: 1.2, height: 1.6)),
                const SizedBox(height: 6),
                Text('EVERY HEART HAS ITS OWN WAY', textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.of(context).green, fontSize: 9, letterSpacing: 2)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.of(context).sage, AppTheme.of(context).panel]), border: Border.all(color: AppTheme.of(context).border),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: AppTheme.of(context).green.withValues(alpha: 0.12), blurRadius: 18, offset: Offset(0, 8))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('매일 3분 마음대화', style: TextStyle(color: AppTheme.of(context).gold, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                    SizedBox(height: 12),
                    Text('오늘 마음은\n어떤가요?', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700, height: 1.15)),
                    SizedBox(height: 12),
                    Text('판단하지 않고, 천천히 마음을 살펴보는 시간입니다.', style: TextStyle(color: AppTheme.of(context).muted, fontSize: 14, height: 1.5)),
                  ]),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: Divider(color: AppTheme.of(context).gold)),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.auto_awesome, size: 14, color: AppTheme.of(context).gold)),
                  Expanded(child: Divider(color: AppTheme.of(context).gold)),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                    child: Text(
                      '지금 가장 가까운 마음을 골라주세요',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.of(context).ink,
                      ),
                    ),
                  ),
                  if (_emotion != null || _otherEmotion || _promotedKeyword != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '선택됨',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.of(context).green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.12,
                  children: [
                    ..._emotionCards.map((card) {
                      final selected = card.customKeyword != null
                          ? _promotedKeyword == card.customKeyword
                          : !_otherEmotion &&
                              _promotedKeyword == null &&
                              card.emotion == _emotion;
                      return Semantics(
                        button: true,
                        selected: selected,
                        label: '${card.label}${selected ? ' 선택됨' : ''}',
                        child: InkWell(
                          onTap: () => card.customKeyword != null
                              ? _selectPromotedKeyword(card.customKeyword!)
                              : _selectEmotion(card.emotion),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.of(context).sage : AppTheme.of(context).panel,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected ? AppTheme.of(context).gold : AppTheme.of(context).border,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Stack(children: [
                              Center(child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(card.icon, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(height: 5),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      card.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: selected ? AppTheme.of(context).ink : AppTheme.of(context).muted,
                                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                              if (selected)
                                Positioned(
                                  top: 7,
                                  right: 7,
                                  child: Icon(Icons.check_circle, size: 17, color: AppTheme.of(context).green),
                                ),
                            ]),
                          ),
                        ),
                      );
                    }),
                    Semantics(
                      button: true,
                      selected: _otherEmotion,
                      label: '기타${_otherEmotion ? ' 선택됨' : ''}',
                      child: InkWell(
                        onTap: () => _selectEmotion(null),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: _otherEmotion ? AppTheme.of(context).sage : AppTheme.of(context).panel,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _otherEmotion ? AppTheme.of(context).gold : AppTheme.of(context).border,
                              width: _otherEmotion ? 1.5 : 1,
                            ),
                          ),
                          child: Stack(children: [
                            Center(child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('✏️', style: TextStyle(fontSize: 20)),
                                const SizedBox(height: 5),
                                Text(
                                  '기타',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _otherEmotion ? AppTheme.of(context).ink : AppTheme.of(context).muted,
                                    fontWeight: _otherEmotion ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                              ],
                            )),
                            if (_otherEmotion)
                              Positioned(
                                top: 7,
                                right: 7,
                                child: Icon(Icons.check_circle, size: 17, color: AppTheme.of(context).green),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_otherEmotion) ...[
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('custom-emotion'),
                    controller: _customEmotion,
                    maxLength: 100,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: '내 마음 직접 적기',
                      hintText: '예: 설레지만 조금 걱정돼요',
                      helperText: '지금 느끼는 감정을 자유롭게 적어 주세요.',
                      helperMaxLines: 3,
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                if (_emotion != null || _otherEmotion || _promotedKeyword != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.of(context).panel,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('마음의 강도', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        Text('${_intensity.round()} / 10', style: TextStyle(color: AppTheme.of(context).green, fontWeight: FontWeight.w800)),
                      ]),
                      Slider(value: _intensity, min: 1, max: 10, divisions: 9, onChanged: (value) => setState(() => _intensity = value)),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: (_otherEmotion ? _customEmotion.text.trim().isEmpty : (_emotion == null && _promotedKeyword == null)) || _loadingUsage || _loadingEmotionCards || _startingConversation
                      ? null
                      : _startConversation,
                    child: const Text('AI 마음대화 시작하기'),
                ),
                const SizedBox(height: 12),
                Text(
                    '사용 횟수 제한 없음 · 오늘 $_dailyUsageCount회 사용',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.of(context).subtle),
                ),
                const SizedBox(height: 4),
                Text('긴급한 위험이 있다면 112, 119 또는 109에 연락해 주세요.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppTheme.of(context).subtle)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDailyUsage();
    _loadEmotionCards();
    _loadVersionInfo();
  }

  @override
  void dispose() {
    _customEmotion.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectEmotion(EmotionType? emotion) {
    setState(() {
      _emotion = emotion;
      _otherEmotion = emotion == null;
      _promotedKeyword = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _selectPromotedKeyword(String keyword) {
    setState(() {
      _emotion = EmotionType.complexity;
      _otherEmotion = false;
      _promotedKeyword = keyword;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _loadEmotionCards() async {
    final stats = await _emotionCardStore.load();
    if (!mounted) return;
    setState(() {
      _emotionStats = stats;
      _loadingEmotionCards = false;
    });
  }

  Future<void> _loadVersionInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionOnly = info.version;
      _versionLabel = 'ONARIA v${info.version} (${info.buildNumber})';
    });
  }

  Future<void> _openLegalUrl(String path) async {
    final uri = Uri.https('onaria.ai.kr', path);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _loadDailyUsage() async {
    final count = await _dailyUsageStore.getCount();
    if (!mounted) return;
    setState(() {
      _dailyUsageCount = count;
      _loadingUsage = false;
    });
  }

  Future<void> _startConversation() async {
    if (_startingConversation || (_otherEmotion ? _customEmotion.text.trim().isEmpty : (_emotion == null && _promotedKeyword == null))) return;
    FocusScope.of(context).unfocus();
    final customEmotion = _otherEmotion
        ? _customEmotion.text.trim()
        : _promotedKeyword;
    final emotion = _emotion ?? EmotionType.complexity;
    setState(() => _startingConversation = true);
    final consumed = await _dailyUsageStore.tryConsume();
    if (_otherEmotion) {
      await _emotionCardStore.recordCustom(customEmotion!);
    } else if (_promotedKeyword != null) {
      await _emotionCardStore.recordCustom(_promotedKeyword!);
    } else {
      await _emotionCardStore.recordPreset(emotion);
    }
    if (!mounted) return;
    if (!consumed) {
      setState(() => _startingConversation = false);
      return;
    }
    setState(() {
      _dailyUsageCount++;
      _startingConversation = false;
    });
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConversationPage(
        emotion: emotion, customEmotion: customEmotion,
        intensity: _intensity.round(),
      ),
    ));
    if (mounted) {
      setState(() {
        _emotion = null;
        _otherEmotion = false;
        _promotedKeyword = null;
        _customEmotion.clear();
        _intensity = 5;
      });
      await _loadEmotionCards();
    }
  }
}
