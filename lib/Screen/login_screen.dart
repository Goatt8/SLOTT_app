import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bababam_app/Widget/container_shadow.dart';
import 'package:bababam_app/Widget/Login/login_sections.dart';
import 'package:bababam_app/Service/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();

  final List<bool> _pageCompleted = [false, false, false];
  final GlobalKey<ProfileSectionState> _profileKey = GlobalKey();
  String _agreedTermsVersion = '';

  int _currentPage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService.checkCurrentUserStatus().then(_handleUserRouting);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleUserRouting(Map<String, dynamic>? authData) async {
    //MARK: Logout state, no user data
    if (authData == null) {
      setState(() => _isLoading = false);
      return;
    }

    final bool isExistingUser = (authData['isExistingUser'] as bool?) ?? false;
    //MARK: Login state, if user exist
    if (isExistingUser) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      //MARK: Login state, user no exist
      setState(() {
        _pageCompleted[0] = true;
        _isLoading = false;
      });

      if (_pageController.hasClients) {
        if (_currentPage == 0) {
          _nextPage();
        } else {
          _pageController.jumpToPage(1);
        }
      }
    }
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
                onPressed: _pageCompleted[_currentPage]
                    ? () async {
                        if (_currentPage == 2) {
                          try {
                            await _profileKey.currentState
                                ?.createUserInProfileSection();
                            if (mounted) {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/home');
                            }
                          } catch (e) {
                            debugPrint("회원 생성 실패: $e");
                          }
                        } else {
                          _nextPage();
                        }
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

  //MARK: Background
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.network(
                'https://i.pinimg.com/736x/dc/af/1d/dcaf1da24d63cefd2204ae13960536d4.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          //MARK: PageView Clouum
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
                        AuthSection(
                          authService: _authService,
                          onVerificationChanged: (result) =>
                              _handleUserRouting(result),
                        ),
                      ),
                      _buildStepCard(
                        "권한 동의",
                        "원활한 이용을 위해\n다음 권한이 필요합니다",
                        PermissionSection(
                          onPermissionChanged: (isCompleted, version) {
                            setState(() {
                              _pageCompleted[1] = isCompleted;
                              _agreedTermsVersion = version;
                            });
                          },
                        ),
                      ),
                      _buildStepCard(
                        "프로필 설정",
                        "프로필 사진과\n사용할 닉네임을 정해주세요",
                        ProfileSection(
                          key: _profileKey,
                          termsVersion: _agreedTermsVersion,
                          onProfileChanged: (isCompleted) {
                            setState(() => _pageCompleted[2] = isCompleted);
                          },
                        ),
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
}
