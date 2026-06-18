import 'package:flutter/services.dart';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:bababam_app/Helper/ui_presets.dart';

import 'package:bababam_app/Model/app_user.dart';

import 'package:bababam_app/Model/group.dart';

import 'package:bababam_app/Model/post.dart';

import 'package:bababam_app/Service/daily_video_export_layout.dart';

class DailyVideoExportService {
  DailyVideoExportService({
    DefaultCacheManager? cacheManager,

    MethodChannel? channel,
  }) : _cacheManager = cacheManager ?? DefaultCacheManager(),

       _channel = channel ?? const MethodChannel('slott/daily_video_export');

  final DefaultCacheManager _cacheManager;

  final MethodChannel _channel;

  final DailyVideoExportLayoutBuilder _layoutBuilder =
      const DailyVideoExportLayoutBuilder();

  Future<DailyVideoExportResult> export({
    required Group group,

    required List<Post> posts,

    required List<AppUser> members,

    required bool useDiceLayout,

    required String dayKey,

    required PostTextStyleSelection textStyleSelection,

    Set<String> blockedUserIds = const {},
  }) async {
    final visiblePosts = posts
        .where((post) => !blockedUserIds.contains(post.authorId))
        .toList();

    final hours = visiblePosts.map((post) => post.hourSlot).toSet().toList()
      ..sort();

    if (hours.isEmpty) {
      throw const DailyVideoExportException('오늘 저장할 영상이 없습니다.');
    }

    final slotOwnerIds = group.effectiveSlotOwnerIds;

    final userById = {for (final member in members) member.id: member};

    final ownerSlotCounts = <String, int>{};

    for (final ownerId in slotOwnerIds) {
      if (ownerId == null) continue;

      ownerSlotCounts[ownerId] = (ownerSlotCounts[ownerId] ?? 0) + 1;
    }

    final localPathByPostId = <String, String>{};

    for (final post in visiblePosts) {
      if (!post.videoUrl.startsWith('http://') &&
          !post.videoUrl.startsWith('https://')) {
        localPathByPostId[post.id] = post.videoUrl;

        continue;
      }

      final cachedFile =
          await _cacheManager.getFileFromCache(post.videoUrl) ??
          await _cacheManager.downloadFile(post.videoUrl);

      localPathByPostId[post.id] = cachedFile.file.path;
    }

    final pageData = hours.map((hour) {
      return {
        'hour': hour,

        'slots': List.generate(slotOwnerIds.length, (slotIndex) {
          final ownerId = slotOwnerIds[slotIndex];

          final user = ownerId == null ? null : userById[ownerId];

          final post = user == null
              ? null
              : _findPostForSlot(
                  posts: visiblePosts,

                  slotIndex: slotIndex,

                  ownerId: user.id,

                  targetHour: hour,

                  allowLegacyUserFallback: ownerSlotCounts[user.id] == 1,
                );

          return {
            'slotIndex': slotIndex,

            'videoPath': post == null ? null : localPathByPostId[post.id],

            'comment': post?.comment ?? '',
          };
        }),
      };
    }).toList();

    final pages = _layoutBuilder.buildPages(
      slotCount: slotOwnerIds.length,
      useDiceLayout: useDiceLayout,
      textStyleSelection: textStyleSelection,
      pages: pageData,
    );

    try {
      final outputPath = await _channel
          .invokeMethod<String>('exportDailyVideo', {
            'slotCount': slotOwnerIds.length,

            'useDiceLayout': useDiceLayout,

            'fontId': textStyleSelection.fontId,

            'colorId': textStyleSelection.colorId,

            'hourFontId': textStyleSelection.hourFontId,

            'dayKey': dayKey,

            'pages': pages,
          });

      if (outputPath == null || outputPath.isEmpty) {
        throw const DailyVideoExportException('완성된 영상 경로를 받지 못했습니다.');
      }

      return DailyVideoExportResult(
        outputPath: outputPath,

        hourCount: hours.length,
      );
    } on PlatformException catch (e) {
      throw DailyVideoExportException(
        '비디오 생성 중 네이티브 오류 발생: ${e.message} (코드: ${e.code})',
      );
    } catch (e) {
      throw DailyVideoExportException('알 수 없는 오류: $e');
    }
  }

  Post? _findPostForSlot({
    required List<Post> posts,

    required int slotIndex,

    required String ownerId,

    required int targetHour,

    required bool allowLegacyUserFallback,
  }) {
    final exact = _latestPost(
      posts.where(
        (post) => post.hourSlot == targetHour && post.slotIndex == slotIndex,
      ),
    );

    if (exact != null || !allowLegacyUserFallback) return exact;

    return _latestPost(
      posts.where(
        (post) =>
            post.hourSlot == targetHour &&
            post.slotIndex == -1 &&
            post.authorId == ownerId,
      ),
    );
  }

  Post? _latestPost(Iterable<Post> posts) {
    Post? latest;

    for (final post in posts) {
      if (latest == null || post.createdAt.isAfter(latest.createdAt)) {
        latest = post;
      }
    }

    return latest;
  }
}

class DailyVideoExportResult {
  const DailyVideoExportResult({
    required this.outputPath,

    required this.hourCount,
  });

  final String outputPath;

  final int hourCount;
}

class DailyVideoExportException implements Exception {
  const DailyVideoExportException(this.message);

  final String message;

  @override
  String toString() => message;
}
