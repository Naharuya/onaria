import 'package:flutter/material.dart';

/// Common vocabulary only; storage and providers remain independent per app.
class DataRightsCopy {
  static const title = '계정과 기록 관리';
  static const localDelete = '이 기기의 내 기록 전체 삭제';
  static const localScope =
      '현재 사용하는 계정 또는 비회원의 카드·실천·여정·임시 문장과 관련 기기 기록을 삭제합니다. 서버 기록과 회원 계정은 삭제하지 않습니다. 다른 회원과 소유자가 확인되지 않은 이전 기록은 유지합니다. 삭제한 기록은 복원할 수 없습니다.';
  static const volatileScope =
      '이번 사용 중의 마음·대화·카드·실천·여정 기록을 모두 지웁니다. 별도로 서버에 저장한 기록과 회원 계정은 삭제하지 않습니다. 삭제한 기록은 복원할 수 없습니다.';
  static const localSuccess = '이 기기의 내 기록을 삭제했어요. 서버 기록과 회원 계정은 유지됩니다.';
  static const deletionFailed = '삭제를 완료하지 못했어요. 일부 기록이 남아 있을 수 있으니 다시 확인해 주세요.';
  static const accountScope =
      '회원탈퇴는 본인 확인 후 이 앱의 서버 계정·연결 로그인·연결된 개인 데이터를 삭제하는 절차입니다. 기기 기록 삭제, 로그아웃, 앱 삭제와는 다릅니다.';
  static const copies =
      '다른 기기의 로컬 기록, 운영체제 백업, 이미 공유·내보낸 사본은 이 기기에서 삭제할 수 없습니다. 각 기기·백업·공유 대상에서 별도로 관리해 주세요.';
  static const withdrawal =
      '저장·AI 동의 철회와 기존 데이터 삭제는 범위가 다릅니다. 철회 후 처리와 이미 저장된 데이터의 삭제 범위를 각각 확인해 주세요.';
  static const outcome =
      '삭제 요청 접수와 삭제 완료를 구분합니다. 실패·통신 중단·처리 결과 미확인 상태에서는 완료로 안내하지 않습니다.';
}

class DataRightsNotice extends StatelessWidget {
  const DataRightsNotice({super.key, this.temporary = false});
  final bool temporary;
  @override
  Widget build(BuildContext context) => Card(
      key: const ValueKey('common-data-rights'),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('기록과 삭제 범위', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(temporary
                ? '이번 사용 중 기록은 메모리에만 남고 다시 시작하면 복원되지 않습니다. 서버 저장은 별도 동의와 저장 동작이 필요합니다.'
                : '이 기기에 저장한 기록은 다른 기기와 자동으로 동기화되지 않습니다. 웹에서는 해당 브라우저의 저장소를 사용합니다.'),
            const SizedBox(height: 8),
            const Text(DataRightsCopy.accountScope),
            const SizedBox(height: 8),
            const Text(DataRightsCopy.copies),
            const SizedBox(height: 8),
            const Text(DataRightsCopy.withdrawal),
          ])));
}
