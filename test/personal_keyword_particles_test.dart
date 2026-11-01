import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/personal_keywords.dart';

void main() {
  test('common Korean particles preserve topic boundaries', () {
    expect(PersonalKeywordLearning.keywords('회사에서는 업무만으로 친구에게 가족과는 학업에도'),
        containsAll(['업무', '친구', '가족', '학업']));
    expect(PersonalKeywordLearning.keywords('회사원 친구들 관계자 미래형 비교적'), isEmpty);
  });
  test('particle variants promote once per submitted message', () {
    final learning = PersonalKeywordLearning();
    for (var i = 0; i < 2; i++) {
      learning.observe('회사에서는 업무만으로 힘들어요.', emotion: '불안', safe: true);
    }
    expect(learning.cards, isEmpty);
    learning.observe('직장에서 업무에 대해 나누고 싶어요.', emotion: '불안', safe: true);
    expect(learning.cards, ['업무']);
  });
}
