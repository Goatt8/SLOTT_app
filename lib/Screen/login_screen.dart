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
  static const List<String> _backgroundEmojiAssets = [
    'assets/emoji/emoji1.png',
    'assets/emoji/emoji4.png',
    'assets/emoji/emoji3.png',
    'assets/emoji/emoji2.png',
  ];

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
  Widget _buildStepCard(
    String title,
    String subtitle,
    Widget content, {
    required bool isKeyboardVisible,
  }) {
    final cardPadding = isKeyboardVisible ? 24.0 : 32.0;
    final contentGap = isKeyboardVisible ? 20.0 : 32.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: isKeyboardVisible ? 12 : 24,
                ),
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
                        padding: EdgeInsets.all(cardPadding),
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
                            SizedBox(height: contentGap),
                            content,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundSlot(String assetPath) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111111).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Opacity(
          opacity: 0.68,
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildSlotBackground() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.9,
            colors: [Color(0xFF242424), Colors.black],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const horizontalPadding = 12.0;
            const slotGap = 10.0;
            const bottomReservedSpace = 148.0;
            final availableWidth =
                constraints.maxWidth - (horizontalPadding * 2);
            final slotWidth = (availableWidth - slotGap) / 2;
            final slotHeight = slotWidth * (16 / 9);
            final boardHeight = (slotHeight * 2) + slotGap;
            final availableHeight =
                constraints.maxHeight - bottomReservedSpace - 24;
            final scale = boardHeight > availableHeight
                ? availableHeight / boardHeight
                : 1.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: bottomReservedSpace),
              child: Center(
                child: SizedBox(
                  width: availableWidth * scale,
                  height: boardHeight * scale,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: slotGap,
                          crossAxisSpacing: slotGap,
                          childAspectRatio: 9 / 16,
                        ),
                    itemCount: _backgroundEmojiAssets.length,
                    itemBuilder: (context, index) {
                      return _buildBackgroundSlot(
                        _backgroundEmojiAssets[index],
                      );
                    },
                  ),
                ),
              ),
            );
          },
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
                  splashFactory: InkSparkle.splashFactory,
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
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildSlotBackground(),
            //MARK: PageView Column
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
                          isKeyboardVisible: isKeyboardVisible,
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
                          isKeyboardVisible: isKeyboardVisible,
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
                          isKeyboardVisible: isKeyboardVisible,
                        ),
                      ],
                    ),
                  ),
                  if (!isKeyboardVisible) _buildBottomIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
