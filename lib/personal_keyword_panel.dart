import 'package:flutter/material.dart';
import 'personal_keywords.dart';

class PersonalKeywordPanel extends StatefulWidget {
  const PersonalKeywordPanel(
      {super.key, required this.learning, required this.onSelected});
  final PersonalKeywordLearning learning;
  final ValueChanged<String> onSelected;
  @override
  State<PersonalKeywordPanel> createState() => _PersonalKeywordPanelState();
}

class _PersonalKeywordPanelState extends State<PersonalKeywordPanel> {
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('자주 쓰는 주제로 카드와 예시 추가'),
            subtitle: const Text(
                '직접 입력한 내용에서 같은 주제가 3번 나오면 추가해요. 이번 사용 중에만 기기에 유지되며, 대화 원문은 추가 저장하지 않아요.'),
            value: widget.learning.enabled,
            onChanged: (value) =>
                setState(() => widget.learning.setEnabled(value))),
        if (widget.learning.cards.isNotEmpty) ...[
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final topic in widget.learning.cards)
              InputChip(
                  key: ValueKey('personal-topic-$topic'),
                  avatar: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(topic),
                  deleteButtonTooltipMessage: '이 주제와 예시 지우기',
                  onDeleted: () =>
                      setState(() => widget.learning.remove(topic)),
                  onPressed: () => widget.onSelected(topic))
          ]),
          TextButton(
              onPressed: () => setState(widget.learning.clear),
              child: const Text('추가된 주제와 예시 지우기')),
        ],
      ]);
}
