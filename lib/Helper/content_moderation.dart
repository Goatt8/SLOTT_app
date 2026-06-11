class ContentModeration {
  ContentModeration._();

  static const Set<String> _blockedTerms = {
    '시발',
    '씨발',
    '병신',
    '개새끼',
    '죽어',
    '섹스',
    '자살',
    'fuck',
    'shit',
    'bitch',
    'nigger',
    'kill yourself',
  };

  static String? rejectionMessage(String text) {
    final normalized = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    for (final term in _blockedTerms) {
      if (normalized.contains(term)) {
        return '부적절하거나 공격적인 표현은 사용할 수 없습니다.';
      }
    }
    return null;
  }
}
