import 'package:flutter/material.dart';

/// App-owned common journey contract. Contains no content, accounts or network.
enum CareStep { emotion, conversation, content, practice, card }

class CareFlow {
  static const version = 1;
  static const order = CareStep.values;
  static bool canAdvance(
          {required int riskLevel, required bool busy, bool current = true}) =>
      current && riskLevel == 0 && !busy;
  static CareStep step(
          {required bool summary,
          required bool actions,
          required bool content}) =>
      summary
          ? CareStep.card
          : actions
              ? CareStep.practice
              : content
                  ? CareStep.content
                  : CareStep.conversation;
}

/// Read-only position, not navigation: cannot bypass consent or safety gates.
class CareFlowProgress extends StatelessWidget {
  const CareFlowProgress(
      {super.key, required this.step, required this.contentLabel});
  final CareStep step;
  final String contentLabel;
  @override
  Widget build(BuildContext context) {
    final labels = ['감정 확인', '마음 대화', contentLabel, '작은 실천', '카드·기록'];
    final label = '${step.index + 1}/5 · ${labels[step.index]}';
    return Semantics(
        key: ValueKey('care-step-${step.name}'),
        container: true,
        label: label,
        child: ExcludeSemantics(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(label,
                    style: Theme.of(context).textTheme.labelMedium))));
  }
}
