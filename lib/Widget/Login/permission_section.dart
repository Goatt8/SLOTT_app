import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:bababam_app/Service/firestore_service.dart';

class PermissionSection extends StatefulWidget {
  const PermissionSection({super.key, required this.onPermissionChanged});

  final Function(bool isAllAgreed, String version) onPermissionChanged;

  @override
  State<PermissionSection> createState() => _PermissionSectionState();
}

class _PermissionSectionState extends State<PermissionSection> {
  bool _cameraAgreed = false;
  bool _termsAgreed = false;
  bool _privacyAgreed = false;

  bool get _isAllChecked => _cameraAgreed && _termsAgreed && _privacyAgreed;

  String _currentTermsVersion = "v1.0.0";
  String _usageTermsUrl = "";
  String _privacyPolicyUrl = "";

  @override
  void initState() {
    super.initState();
    FireStoreService().getAppSetting().then((setting) {
      if (setting != null && mounted) {
        setState(() {
          _currentTermsVersion = setting.currentVersion;
          _usageTermsUrl = setting.usageTermsUrl;
          _privacyPolicyUrl = setting.privacyPolicyUrl;
        });
      }
    });
  }

  void _notify() {
    widget.onPermissionChanged(
      _cameraAgreed && _termsAgreed && _privacyAgreed,
      _currentTermsVersion,
    );
  }

  //MARK: All Agree
  void _toggleAll(bool? data) {
    final targetState = data ?? !_isAllChecked;
    setState(() {
      _termsAgreed = targetState;
      _privacyAgreed = targetState;

      if (targetState) {
        _requestCameraPermission();
      } else {
        _cameraAgreed = false;
      }
    });
    _notify();
  }

  //MARK: Request
  // Future<void> _requestCameraPermission() async {
  //   if (_cameraAgreed) {
  //     setState(() => _cameraAgreed = false);
  //     _notify();
  //     return;
  //   }

  //   PermissionStatus status = await Permission.camera.status;
  //   //MARK: User Reject
  //   if (status.isPermanentlyDenied) {
  //     if (mounted) {
  //       _showSettingsDialog();
  //     }
  //     return;
  //   }

  //   status = await Permission.camera.request();

  //   if (status.isGranted) {
  //     setState(() => _cameraAgreed = true);
  //   } else if (status.isPermanentlyDenied || status.isRestricted) {
  //     if (mounted) _showSettingsDialog();
  //   }
  //   _notify();
  // }

  //MARK: 테스트용 카메라 동의로직
  Future<void> _requestCameraPermission() async {
    setState(() {
      _cameraAgreed = !_cameraAgreed;
    });
    _notify();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카메라 권한 필요'),
        content: const Text('카메라 기능 사용을 위해 스마트폰 설정에서 카메라 권한을 허용해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              //MARK: App Setting
              openAppSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  void _showWebViewDialog({required String title, required String url}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(url)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAllAgreeRow() {
    return InkWell(
      onTap: () => _toggleAll(!_isAllChecked),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(
              _isAllChecked ? Icons.check_circle : Icons.check_circle_outline,
              color: _isAllChecked ? Colors.greenAccent : Colors.white38,
              size: 26,
            ),
            const SizedBox(width: 12),
            const Text(
              "약관 전체동의",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementRow({
    required String text,
    required bool value,
    required VoidCallback onTap,
    VoidCallback? onArrowPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 8.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      value ? Icons.check_circle : Icons.check_circle_outline,
                      color: value ? Colors.white : Colors.white38,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (onArrowPressed != null)
            IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 14,
              ),
              onPressed: onArrowPressed,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAllAgreeRow(),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(color: Colors.white24, height: 1),
        ),

        _buildAgreementRow(
          text: "이용약관 동의 (필수)",
          value: _termsAgreed,
          onTap: () {
            setState(() => _termsAgreed = !_termsAgreed);
            _notify();
          },
          onArrowPressed: () {
            _showWebViewDialog(title: "바바밤 이용약관", url: _usageTermsUrl);
          },
        ),
        _buildAgreementRow(
          text: "개인정보 수집 및 이용동의 (필수)",
          value: _privacyAgreed,
          onTap: () {
            setState(() => _privacyAgreed = !_privacyAgreed);
            _notify();
          },
          onArrowPressed: () {
            _showWebViewDialog(title: "바바밤 개인정보 보호정책", url: _privacyPolicyUrl);
          },
        ),
      ],
    );
  }
}
