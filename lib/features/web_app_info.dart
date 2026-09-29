import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> requestWebAiConsent(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI 대화를 시작하기 전에'),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                '입력한 대화, 선택한 감정과 강도, 최근 대화 맥락을 ONARIA 서버로 전송해요. 외부 AI가 활성화된 경우 답변 생성을 위해 OpenAI에도 전달돼요. 이름·연락처 등 개인을 식별할 수 있는 내용은 입력하지 말아 주세요.'),
            const SizedBox(height: 12),
            const Text(
                'AI 답변은 의료 진단·치료나 전문 상담을 대신하지 않아요. 동의하지 않아도 저장한 기록과 별 모으기는 사용할 수 있어요.'),
            TextButton(
              onPressed: () => launchUrl(Uri.https('onaria.ai.kr', '/privacy'),
                  mode: LaunchMode.externalApplication),
              child: const Text('개인정보 처리방침 보기'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('전송에 동의하고 계속'),
          ),
        ],
      ),
    ) ??
    false;

Future<void> showWebAppInfo(BuildContext context) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('웹앱 이용 안내'),
        scrollable: true,
        content: const Text(
          '홈 화면에 추가\niPhone Safari는 공유 메뉴 → 홈 화면에 추가, Android Chrome은 브라우저 메뉴 → 홈 화면에 추가를 이용해 주세요.\n\n'
          '나의 기록\n저장한 카드와 여정은 현재 브라우저에 보관돼요. 다른 기기와 자동 동기화되지 않으며 브라우저 데이터를 지우면 사라질 수 있어요. 공용 기기에서는 민감한 기록을 남기지 말아 주세요.\n\n'
          '인터넷과 권한\n앱을 열거나 AI와 대화하려면 인터넷 연결이 필요해요. 음성 입력과 이미지 공유는 브라우저 지원과 권한에 따라 달라져요. 공유를 지원하지 않는 브라우저에서는 이미지 다운로드로 이어질 수 있어요. 예약 알림은 모바일 앱에서 사용할 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
