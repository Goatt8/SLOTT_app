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
    final videoUrls = await _firestoreService.getGroupPostVideoUrlsOlderThan(
      groupId: groupId,
      retention: retention,
    );

    await _fireStorageService.deleteVideosByUrls(videoUrls);
    return videoUrls.length;
  }
}
