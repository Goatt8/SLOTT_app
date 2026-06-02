import 'package:flutter/material.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PermissionSection extends StatefulWidget {
  const PermissionSection({super.key, required this.onPermissionChanged});

  final Function(bool isAllAgreed, String version) onPermissionChanged;

  @override
  State<PermissionSection> createState() => _PermissionSectionState();
}

class _PermissionSectionState extends State<PermissionSection> {
  static const String _defaultUsageTermsUrl =
      'https://doc-hosting.flycricket.io/bababam-terms-of-use/807e91b4-6b11-44b7-ab31-f6a0f1bd69fc/terms';
  static const String _defaultPrivacyPolicyUrl =
      'https://doc-hosting.flycricket.io/bababam-privacy-policy/3af0cab3-9f97-4aa7-87fd-72c59c1dae20/privacy';

  bool _cameraAgreed = false;
  bool _termsAgreed = false;
  bool _privacyAgreed = false;

  bool get _isAllChecked => _cameraAgreed && _termsAgreed && _privacyAgreed;

  String _currentTermsVersion = "v1.0.0";
  String _usageTermsUrl = _defaultUsageTermsUrl;
  String _privacyPolicyUrl = _defaultPrivacyPolicyUrl;

  @override
  void initState() {
    super.initState();
    FireStoreService().getAppSetting().then((setting) {
      if (setting != null && mounted) {
        setState(() {
          _currentTermsVersion = setting.currentVersion;
          _usageTermsUrl = setting.usageTermsUrl.isNotEmpty
              ? setting.usageTermsUrl
              : _defaultUsageTermsUrl;
          _privacyPolicyUrl = setting.privacyPolicyUrl.isNotEmpty
              ? setting.privacyPolicyUrl
              : _defaultPrivacyPolicyUrl;
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
      if (!targetState) {
        _cameraAgreed = false;
      }
    });

    if (targetState && !_cameraAgreed) {
      _requestCameraPermission();
    } else {
      _notify();
    }
  }

  //MARK: Camera Agreement
  Future<void> _requestCameraPermission() async {
    setState(() {
      _cameraAgreed = !_cameraAgreed;
    });
    _notify();
  }

  void _showWebViewDialog({required String title, required String url}) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        !['http', 'https'].contains(uri.scheme)) {
      WarningSnackBar.showWarning(context, '약관 페이지 주소가 올바르지 않습니다.');
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(uri);

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
              child: WebViewWidget(controller: controller),
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
          text: "카메라 권한 동의 (필수)",
          value: _cameraAgreed,
          onTap: () => _requestCameraPermission(),
        ),

        _buildAgreementRow(
          text: "이용약관 동의 (필수)",
          value: _termsAgreed,
          onTap: () {
            setState(() => _termsAgreed = !_termsAgreed);
            _notify();
          },
          onArrowPressed: () {
            if (_usageTermsUrl.isNotEmpty) {
              _showWebViewDialog(title: "바바밤 이용약관", url: _usageTermsUrl);
            } else {
              WarningSnackBar.showWarning(context, '약관을 불러오는중입니다. 다시 시도해주세요.');
            }
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
            if (_privacyPolicyUrl.isNotEmpty) {
              _showWebViewDialog(
                title: "바바밤 개인정보 보호정책",
                url: _privacyPolicyUrl,
              );
            } else {
              WarningSnackBar.showWarning(context, '약관을 불러오는중입니다. 다시 시도해주세요.');
            }
          },
        ),
      ],
    );
  }
}
