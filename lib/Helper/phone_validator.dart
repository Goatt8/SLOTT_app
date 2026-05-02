class PhoneValidator {
  static bool isValidKoreanNumber(String number) {
    String cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    RegExp regExp = RegExp(r'^010[0-9]{8}$');
    return regExp.hasMatch(cleanNumber);
  }

  static String formatToFirebase(String number) {
    String cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    return "+82${cleanNumber.substring(1)}";
  }
}
