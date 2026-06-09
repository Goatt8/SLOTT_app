import 'package:bababam_app/Service/firestorage_service.dart';
import 'package:bababam_app/Service/firestore_service.dart';

class PostVideoCleanupService {
  PostVideoCleanupService({
    FireStoreService? firestoreService,
    FireStorageService? fireStorageService,
  }) : _firestoreService = firestoreService ?? FireStoreService(),
       _fireStorageService = fireStorageService ?? FireStorageService();

  static const Duration defaultRetention = Duration(days: 2);

  final FireStoreService _firestoreService;
  final FireStorageService _fireStorageService;

  Future<int> deleteGroupPostVideosOlderThan({
    required String groupId,
    Duration retention = defaultRetention,
  }) async {
    final videoUrls = await _firestoreService.deleteGroupPostsOlderThan(
      groupId: groupId,
      retention: retention,
    );

    await deleteUnreferencedOwnedVideos(videoUrls);
    return videoUrls.length;
  }

  Future<void> deleteUnreferencedOwnedVideos(Iterable<String> videoUrls) async {
    for (final videoUrl in videoUrls.toSet()) {
      final isStillReferenced = await _firestoreService.hasPostReferenceToVideo(
        videoUrl,
      );
      if (!isStillReferenced) {
        await _fireStorageService.deleteVideoByUrl(videoUrl);
      }
    }
  }
}
