class AppSetting {
  final String currentVersion;
  final String privacyPolicyUrl;
  final String usageTermsUrl;

  AppSetting({
    required this.currentVersion,
    required this.privacyPolicyUrl,
    required this.usageTermsUrl,
  });

  factory AppSetting.fromFirestore(Map<String, dynamic> data) {
    return AppSetting(
      currentVersion: data['current_version'] ?? 'v1.0.0',
      privacyPolicyUrl: data['privacy_policy_url'] ?? '',
      usageTermsUrl: data['usage_terms_url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current_version': currentVersion,
      'privacy_policy_url': privacyPolicyUrl,
      'usage_terms_url': usageTermsUrl,
    };
  }
}
