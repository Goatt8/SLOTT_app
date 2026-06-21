import 'package:bababam_app/Model/current_post_preview.dart';
import 'package:bababam_app/Helper/ui_presets.dart';

class AppUser {
  final String id;
  final String name;
  final String phoneNumber;
  final String? profileUrl;
  final String fontId;
  final String colorId;
  final String hourFontId;
  final List<String> blockedUserIds;
  final CurrentPostPreview? currentPost;

  final bool hasAgreedTerms;
  final String? termsVersion;
  final bool isDeleted;
  final bool hasUnreadNotification;
  final List<String> unreadGroupIds;

  AppUser({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.fontId = AppTypography.defaultPostFontId,
    this.colorId = AppTypography.defaultPostColorId,
    this.hourFontId = AppTypography.defaultHourFontId,
    this.blockedUserIds = const [],
    this.profileUrl,
    this.currentPost,
    this.hasAgreedTerms = false,
    this.termsVersion,
    this.isDeleted = false,
    this.hasUnreadNotification = false,
    this.unreadGroupIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'profileUrl': profileUrl,
      'fontId': fontId,
      'colorId': colorId,
      'hourFontId': hourFontId,
      'blockedUserIds': blockedUserIds,
      'currentPost': currentPost?.toMap(),
      'termsInfo': {'hasAgreed': hasAgreedTerms, 'version': termsVersion},
      'isDeleted': isDeleted,
      'hasUnreadNotification': hasUnreadNotification,
      'unreadGroupIds': unreadGroupIds,
    };
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    final termsInfo = map['termsInfo'] as Map<String, dynamic>?;

    return AppUser(
      id: id,
      name: map['name'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      profileUrl: map['profileUrl'] as String?,
      fontId:
          map['fontId'] as String? ??
          map['defaultPostFontId'] as String? ??
          AppTypography.defaultPostFontId,
      colorId:
          map['colorId'] as String? ??
          map['defaultPostColorId'] as String? ??
          AppTypography.defaultPostColorId,
      hourFontId:
          map['hourFontId'] as String? ??
          map['defaultHourFontId'] as String? ??
          AppTypography.defaultHourFontId,
      blockedUserIds: List<String>.from(
        map['blockedUserIds'] as List<dynamic>? ?? const [],
      ),
      currentPost: map['currentPost'] != null
          ? CurrentPostPreview.fromMap(
              map['currentPost'] as Map<String, dynamic>,
            )
          : null,

      hasAgreedTerms: termsInfo?['hasAgreed'] as bool? ?? false,
      termsVersion: termsInfo?['version'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      hasUnreadNotification: map['hasUnreadNotification'] as bool? ?? false,
      unreadGroupIds: List<String>.from(
        map['unreadGroupIds'] as List<dynamic>? ?? const [],
      ),
    );
  }

  bool get shouldShowUploadForm {
    if (currentPost == null) return true;

    final now = DateTime.now();
    final lastTime = currentPost!.createdAt;

    return now.year != lastTime.year ||
        now.month != lastTime.month ||
        now.day != lastTime.day ||
        now.hour != lastTime.hour;
  }
}
