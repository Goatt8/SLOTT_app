import 'package:bababam_app/Model/post_video_file.dart';
import 'package:bababam_app/Service/firestorage_service.dart';
import 'package:bababam_app/Service/firestore_service.dart';

class PostVideoCleanupService {
  PostVideoCleanupService({
    FireStoreService? firestoreService,
    FireStorageService? fireStorageService,
  }) : _firestoreService = firestoreService ?? FireStoreService(),
       _fireStorageService = fireStorageService ?? FireStorageService();

  static const Duration defaultRetention = Duration(days: 3);

  final FireStoreService _firestoreService;
  final FireStorageService _fireStorageService;

  Future<void> deleteVideos(Iterable<PostVideoFile> videoFiles) async {
    await _fireStorageService.deletePostVideoFiles(videoFiles);
  }

  Future<int> deleteGroupPostVideosOlderThan({
    required String groupId,
    Duration retention = defaultRetention,
  }) async {
    final videoFiles = await _firestoreService.deleteGroupPostsOlderThan(
      groupId: groupId,
      retention: retention,
    );

    await deleteUnreferencedOwnedVideos(videoFiles);
    return videoFiles.length;
  }

  Future<void> deleteUnreferencedOwnedVideos(
    Iterable<PostVideoFile> videoFiles,
  ) async {
    final uniqueVideoFiles = <String, PostVideoFile>{};
    for (final videoFile in videoFiles) {
      if (!videoFile.hasReference) continue;
      final key = videoFile.storagePath?.isNotEmpty == true
          ? videoFile.storagePath!
          : videoFile.videoUrl!;
      uniqueVideoFiles[key] = videoFile;
    }

    for (final videoFile in uniqueVideoFiles.values) {
      final isStillReferenced = await _firestoreService
          .hasPostReferenceToVideoFile(videoFile);
      if (!isStillReferenced) {
        await _fireStorageService.deleteVideo(
          videoUrl: videoFile.videoUrl,
          storagePath: videoFile.storagePath,
        );
      }
    }
  }
}
