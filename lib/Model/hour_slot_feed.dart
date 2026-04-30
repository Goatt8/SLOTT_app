import 'package:bababam_app/Model/post.dart';

class HourSlotFeed {
  final int hourSlot;
  final List<Post> posts;

  const HourSlotFeed({required this.hour, required this.posts});
}
