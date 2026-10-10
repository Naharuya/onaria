import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Version changes require a fresh decision; no conversation content is stored.
class AiConsent {
  static const version = 'openai-chat-v1';
  static const preferenceKey = 'onaria.external_ai_consent_version';
  static const disclosure =
      '받는 곳: ONARIA 서버와 외부 AI 제공자 OpenAI(외부 AI가 활성화된 경우).\n\n'
      '전달 항목: 입력한 대화, 선택한 감정·강도, 필요한 이전 답변·질문과 대화 요약. 이름·전화번호·로그인 토큰은 AI 요청에 포함하지 않아요. 민감한 개인 정보는 입력하지 마세요.\n\n'
      '목적: 마음 대화 답변과 관련 말씀 안내 생성. OpenAI 요청은 응답 저장 옵션을 끄지만, 이것이 제공자의 모든 보관을 없앤다는 뜻은 아니에요. 제공자 처리 조건은 개인정보처리방침에서 확인해 주세요.\n\n'
      '허용하지 않으면 이 대화를 서버에 보내지 않아요. 계정과 기록 관리에서 언제든 허용을 철회할 수 있어요.';

  static Future<bool> isGranted() async =>
      await SharedPreferencesAsync().getString(preferenceKey) == version;
  static Future<void> grant() =>
      SharedPreferencesAsync().setString(preferenceKey, version);
  static Future<void> withdraw() =>
      SharedPreferencesAsync().remove(preferenceKey);

  static Future<bool> request(BuildContext context) async {
    if (await isGranted()) return true;
    if (!context.mounted) return false;
    bool adultConfirmed = false;
    final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                  title: const Text('외부 AI 전송을 허용할까요?'),
                  content: SingleChildScrollView(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('만 18세 이상입니다.'),
                        value: adultConfirmed,
                        onChanged: (value) => setDialogState(
                            () => adultConfirmed = value == true),
                      ),
                      const Text(disclosure),
                    ],
                  )),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('전송하지 않기')),
                    FilledButton(
                        onPressed: adultConfirmed
                            ? () => Navigator.pop(context, true)
                            : null,
                        child: const Text('허용하고 보내기')),
                  ],
                )));
    if (accepted != true) return false;
    await grant();
    return true;
  }
}
