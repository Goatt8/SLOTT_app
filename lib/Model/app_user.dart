import 'package:bababam_app/Model/current_post_preview.dart';
import 'package:bababam_app/Helper/ui_presets.dart';

class AppUser {
  final String id;
  final String name;
  final String phoneNumber;
  final String? profileUrl;
  final String fontId;
  final String colorId;
  final CurrentPostPreview? currentPost;

  AppUser({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.fontId = AppTypography.defaultPostFontId,
    this.colorId = AppTypography.defaultPostColorId,
    this.profileUrl,
    this.currentPost,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'profileUrl': profileUrl,
      'fontId': fontId,
      'colorId': colorId,
      'currentPost': currentPost?.toMap(),
    };
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
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
      currentPost: map['currentPost'] != null
          ? CurrentPostPreview.fromMap(
              map['currentPost'] as Map<String, dynamic>,
            )
          : null,
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
