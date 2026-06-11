import 'package:bababam_app/Helper/phone_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bababam_app/Helper/content_moderation.dart';

void main() {
  test('validates Korean mobile phone numbers', () {
    expect(PhoneValidator.isValidKoreanNumber('01012345678'), isTrue);
    expect(PhoneValidator.isValidKoreanNumber('010-1234-5678'), isTrue);
    expect(PhoneValidator.isValidKoreanNumber('0101234567'), isFalse);
  });

  test('formats Korean mobile phone numbers for Firebase Auth', () {
    expect(PhoneValidator.formatToFirebase('010-1234-5678'), '+821012345678');
  });

  test('rejects objectionable text content', () {
    expect(ContentModeration.rejectionMessage('상대를 괴롭히는 씨발 표현'), isNotNull);
    expect(ContentModeration.rejectionMessage('오늘도 산책 중'), isNull);
  });
}
