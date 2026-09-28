export 'src/conversation_state.dart';
export 'src/crisis_detector.dart';
export 'src/crisis_models.dart';
export 'src/emotion.dart';
export 'src/check_in.dart';

String localCrisisMessage(int level) => level >= 3
    ? '지금은 안전을 확보하는 일이 가장 중요합니다. 가능하다면 위험한 물건에서 멀어지고, 믿을 수 있는 사람에게 곁에 있어 달라고 부탁해 주세요. 다쳤거나 자신 또는 다른 사람을 곧 해칠 위험이 있다면 현지 응급 서비스에 바로 연락해 주세요. 한국에서는 응급 구조 119·긴급 신고 112를 이용할 수 있습니다. 저는 직접 출동하거나 구조를 요청할 수 없습니다.'
    : '그 마음을 혼자 견디지 않으셔도 됩니다. 믿을 수 있는 주변 사람에게 지금 상태를 알리고, 상담 전문가나 의료진의 도움을 받아 주세요. 한국에서는 자살예방상담전화 109에 연락할 수 있습니다. 지금 다쳤거나 자신 또는 다른 사람을 해칠 위험이 급박하면 현지 응급 서비스에 바로 연락해 주세요. 한국에서는 119·112를 이용할 수 있습니다.';
