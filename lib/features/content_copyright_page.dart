import 'package:flutter/material.dart';

import '../app/space_scaffold.dart';

class ContentCopyrightPage extends StatelessWidget {
  const ContentCopyrightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SpaceScaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                Align(alignment: Alignment.centerLeft, child: BackButton()),
                SizedBox(height: 12),
                Text('콘텐츠 및 성경 저작권',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                SizedBox(height: 24),
                _LicenseSection(
                  title: '한국어 성경',
                  body:
                      'ONARIA 1차 출시에서 제공하는 한국어 성경 본문은 성경전서 개역한글판(1961)을 기준으로 합니다. 출처는 대한성서공회이며, 저작재산권 보호기간 종료 이후에도 성명표시와 본문 동일성 유지 원칙을 존중합니다.',
                ),
                _LicenseSection(
                  title: '영어 성경',
                  body:
                      '1차 출시에서는 NIV 본문을 제공하지 않습니다. 영어 성경 기능은 출처와 사용 조건 검증이 완료된 번역본만 추가합니다. 기존 테스트 과정에서 저장된 영어 본문은 새 카드·공유·낭독 콘텐츠에 사용하지 않습니다.',
                ),
                _LicenseSection(
                  title: 'ONARIA 자체 콘텐츠',
                  body:
                      '묵상 질문, 작은 실천, Cross Light 문구 등 ONARIA가 자체 작성한 콘텐츠는 별도 출처가 표시되지 않는 한 ONARIA 자체 콘텐츠입니다.',
                ),
                _LicenseSection(
                  title: '오픈소스',
                  body:
                      'Flutter 및 사용 중인 오픈소스 패키지의 개별 라이선스는 메뉴의 “오픈소스 라이선스”에서 확인할 수 있습니다.',
                ),
                _LicenseSection(
                  title: '문의',
                  body: '콘텐츠 및 권리 관련 문의: vjsjv7003@naver.com',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LicenseSection extends StatelessWidget {
  const _LicenseSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.65)),
        ],
      ),
    );
  }
}
