import 'package:bababam_app/Helper/phone_validator.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';
import 'package:bababam_app/Service/auth_service.dart';
import 'package:bababam_app/Widget/custom_text_field.dart';
import 'package:flutter/material.dart';

class AuthSection extends StatefulWidget {
  final AuthService authService;
  final Function(Map<String, dynamic>?) onVerificationChanged;

  const AuthSection({
    super.key,
    required this.authService,
    required this.onVerificationChanged,
  });

  @override
  State<AuthSection> createState() => _AuthSectionState();
}

class _AuthSectionState extends State<AuthSection> {
  static const double _fieldHeight = 54.0;
  static const double _radius = 16.0;

  final TextEditingController _phoneNumController = TextEditingController();
  final TextEditingController _verifyCodeController = TextEditingController();

  bool _isCodeSent = false;
  bool _isVerified = false;
  String _phoneNumber = "";

  @override
  void dispose() {
    _phoneNumController.dispose();
    _verifyCodeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!PhoneValidator.isValidKoreanNumber(_phoneNumber)) {
      WarningSnackBar.showWarning(context, "휴대폰 번호 형식을 다시 입력해주세요.");
      return;
    }

    final formatted = PhoneValidator.formatToFirebase(_phoneNumber);
    try {
      await widget.authService.sendCode(formatted, (_) {
        setState(() => _isCodeSent = true);
      });
    } catch (_) {
      if (!mounted) return;
      WarningSnackBar.showWarning(context, "인증번호 전송 실패");
    }
  }

  Future<void> _verifyCode() async {
    final userOTP = _verifyCodeController.text.trim();
    if (userOTP.length != 6) {
      WarningSnackBar.showWarning(context, "인증번호 6자리 형식이 아닙니다.");
      return;
    }

    try {
      final verifiedResult = await widget.authService.verifyCode(userOTP);
      if (verifiedResult != null) {
        setState(() => _isVerified = true);
        widget.onVerificationChanged(verifiedResult);
      }
    } catch (_) {
      if (!mounted) return;
      WarningSnackBar.showWarning(context, "인증에 실패했습니다");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _isVerified
          ? _buildVerificationComplete()
          : _buildVerificationForm(),
    );
  }

  Widget _buildVerificationComplete() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.greenAccent),
          SizedBox(width: 10),
          Text(
            '휴대폰 번호 인증이 완료되었습니다',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                hint: "휴대폰 번호 입력",
                controller: _phoneNumController,
                keyboardType: TextInputType.number,
                radius: _radius,
                onChanged: (val) => _phoneNumber = val,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: _fieldHeight,
              child: ElevatedButton(
                onPressed: _requestCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_radius),
                  ),
                ),
                child: Text(_isCodeSent ? "재전송" : "인증요청"),
              ),
            ),
          ],
        ),
        if (_isCodeSent) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hint: "인증번호 6자리 입력",
                  controller: _verifyCodeController,
                  keyboardType: TextInputType.number,
                  radius: _radius,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: _fieldHeight,
                child: ElevatedButton(
                  onPressed: _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isVerified ? Colors.green : Colors.white,
                    foregroundColor: _isVerified ? Colors.white : Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                  ),
                  child: Text(_isVerified ? "성공" : "확인"),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
