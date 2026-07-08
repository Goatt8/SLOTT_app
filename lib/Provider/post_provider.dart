import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Service/firestore_service.dart';

final firestoreServiceProvider = Provider<FireStoreService>((ref) {
  return FireStoreService();
});

typedef GroupPostsArgs = ({String groupId, String dayKey});

final groupPostsProvider = StreamProvider.family<List<Post>, GroupPostsArgs>((
  ref,
  args,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);

  return firestoreService.getPostsByDayStream(
    groupId: args.groupId,
    dayKey: args.dayKey,
  );
});
