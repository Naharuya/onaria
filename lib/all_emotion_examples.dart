import 'package:flutter/material.dart';
import 'common_emotion_examples.dart';

class AllEmotionExamples extends StatelessWidget {
  const AllEmotionExamples(
      {super.key,
      this.emotion = '이런',
      this.compact = false,
      this.isExcluded,
      required this.examples,
      required this.onSelected});
  final String emotion;
  final bool Function(String)? isExcluded;
  final bool compact;
  final List<String> examples;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final situations =
        examples.isEmpty ? commonGenericSituationExamples : examples;
    Future<void> open() async {
      final value = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                title: const Text('감정 예시 모두 보기'),
                content: SizedBox(
                    width: 420,
                    height: 400,
                    child: ListView(children: [
                      Text('$emotion 카드의 예시'),
                      for (final text in situations
                          .where((text) => !(isExcluded?.call(text) ?? false)))
                        ListTile(
                            title: Text(text),
                            onTap: () => Navigator.pop(dialogContext, text)),
                      ExpansionTile(
                          title: const Text('공통 대화 예시 전체'),
                          children: [
                            for (final text
                                in commonConversationExamplesFor(emotion).where(
                                    (text) =>
                                        !(isExcluded?.call(text) ?? false)))
                              ListTile(
                                  title: Text(text),
                                  onTap: () =>
                                      Navigator.pop(dialogContext, text))
                          ]),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('닫기'))
                ],
              ));
      if (context.mounted && value != null) onSelected(value);
    }

    return compact
        ? IconButton(
            key: const ValueKey('all-emotion-examples'),
            tooltip: '감정 예시 모두 보기',
            icon: const Icon(Icons.list_alt),
            onPressed: open)
        : TextButton.icon(
            key: const ValueKey('all-emotion-examples'),
            icon: const Icon(Icons.list_alt),
            label: const Text('감정 예시 모두 보기'),
            onPressed: open);
  }
}
