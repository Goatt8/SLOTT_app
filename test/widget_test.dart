import 'package:bababam_app/Helper/phone_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validates Korean mobile phone numbers', () {
    expect(PhoneValidator.isValidKoreanNumber('01012345678'), isTrue);
    expect(PhoneValidator.isValidKoreanNumber('010-1234-5678'), isTrue);
    expect(PhoneValidator.isValidKoreanNumber('0101234567'), isFalse);
  });

  test('formats Korean mobile phone numbers for Firebase Auth', () {
    expect(PhoneValidator.formatToFirebase('010-1234-5678'), '+821012345678');
  });
}
