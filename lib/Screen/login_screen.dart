import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bababam_app/Widget/container_shadow.dart';
import 'package:bababam_app/Service/auth_service.dart';
import 'package:bababam_app/Helper/phone_validator.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  final TextEditingController _phoneNumController = TextEditingController();
  final TextEditingController _verifyCodeController = TextEditingController();

  static const double _fieldHeight = 54.0;
  static const double _radius = 16.0;
  static const Color _glassColor = Colors.white12;

  int _currentPage = 0;
  bool _isCompletePage = false;
  bool _isCodeSent = false;
  String _phoneNumber = "";
  String _smsCode = "";

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  //MARK: Background
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.network(
                'https://i.pinimg.com/1200x/b9/82/41/b9824142d3db284b59756c5893cebf54.jpg', // 임시 배경 사진
                fit: BoxFit.cover,
              ),
            ),
          ),

          //MARK: Main
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _buildStepCard(
                        "휴대폰 번호 인증",
                        "인증번호를 받기 위해\n번호를 입력해주세요\n(-없이 010xxxxxxxx)",
                        _buildAuthInput(),
                      ),
                      _buildStepCard(
                        "권한 동의",
                        "원활한 이용을 위해\n다음 권한이 필요합니다",
                        _buildPermissionList(),
                      ),
                      _buildStepCard(
                        "프로필 설정",
                        "함께 사용할\n이름과 사진을 정해주세요",
                        _buildProfileInput(),
                      ),
                    ],
                  ),
                ),
                _buildBottomIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //MARK: Glass card
  Widget _buildStepCard(String title, String subtitle, Widget content) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: ContainerShadow(
          borderRadius: 32,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    content,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //MARK: Bottom Indicator Dot
  Widget _buildBottomIndicator() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          //MARK: NextPageButton
          const SizedBox(height: 24),
          ContainerShadow(
            borderRadius: 20,
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isCompletePage
                    ? () {
                        _nextPage();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,

                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white30,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentPage == 2 ? "시작하기" : "다음으로",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //MARK: buildAuthInput()
  Widget _buildAuthInput() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _customTextField(
                  "휴대폰 번호 입력",
                  _phoneNumController,
                  onChanged: (val) {
                    _phoneNumber = val;
                  },
                ),
              ),
              //MARK: codeSendButton
              const SizedBox(width: 8),
              SizedBox(
                height: _fieldHeight,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!PhoneValidator.isValidKoreanNumber(_phoneNumber)) {
                      WarningSnackBar.showWarning(
                        context,
                        "휴대폰 번호 형식을 다시 입력해주세요.",
                      );
                      return;
                    }
                    String formatted = PhoneValidator.formatToFirebase(
                      _phoneNumber,
                    );

                    try {
                      await _authService.sendCode(formatted, (verificationId) {
                        setState(() {
                          _isCodeSent = true;
                        });
                        print("인증번호 발송 성공!");
                      });
                    } catch (e) {
                      WarningSnackBar.showWarning(context, "인증번호 전송 실패");
                    }
                  },
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
                  child: _customTextField(
                    "인증번호 6자리 입력",
                    _verifyCodeController,
                    onChanged: (val) {
                      _phoneNumber = val;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: _fieldHeight,
                  child: ElevatedButton(
                    onPressed: () async {
                      String userOTP = _verifyCodeController.text.trim();
                      if (userOTP.length != 6) {
                        print("인증번호 6자리 형식이 아닙니다.");
                        WarningSnackBar.showWarning(
                          context,
                          "인증번호 6자리 형식이 아닙니다.",
                        );
                        return;
                      }
                      try {
                        final verifiedResult = await _authService.verifyCode(
                          userOTP,
                        );
                        if (verifiedResult != null) {
                          setState(() {
                            _isCompletePage = true;
                          });
                          print("인증 성공!");
                        }
                      } catch (e) {
                        print("인증 실패: $e");
                        WarningSnackBar.showWarning(context, "인증에 실패했습니다");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCompletePage
                          ? Colors.green
                          : Colors.white,
                      foregroundColor: _isCompletePage
                          ? Colors.white
                          : Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                    ),
                    child: Text(_isCompletePage ? "성공" : "확인"),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  //MARK: buildPermissonList
  Widget _buildPermissionList() =>
      Column(children: [_checkRow("카메라 권한 필수"), _checkRow("이용약관 동의")]);
  //MARK: buildProfileInput
  Widget _buildProfileInput() =>
      _customTextField("닉네임 입력", _verifyCodeController);
  //MARK: customTextField
  Widget _customTextField(
    String hint,
    TextEditingController controller, {
    Function(String)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _checkRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
