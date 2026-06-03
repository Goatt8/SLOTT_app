import 'package:bababam_app/Model/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String title;
  final String ownerId;
  final List<String> memberIds;
  final int memberCount;
  final List<String?> slotOwnerIds;
  final List<Post>? post;

  Group({
    required this.id,
    required this.title,
    required this.memberIds,
    required this.ownerId,
    required this.memberCount,
    required this.slotOwnerIds,
    this.post,
  });

  int get slotCount {
    var count = memberCount;
    if (slotOwnerIds.length > count) count = slotOwnerIds.length;
    if (memberIds.length > count) count = memberIds.length;
    return count;
  }

  List<String?> get effectiveSlotOwnerIds {
    return List<String?>.generate(slotCount, (index) {
      if (index < slotOwnerIds.length && slotOwnerIds[index] != null) {
        return slotOwnerIds[index];
      }
      if (index < memberIds.length) {
        return memberIds[index];
      }
      return null;
    });
  }

  int get occupiedSlotCount {
    return effectiveSlotOwnerIds.where((ownerId) => ownerId != null).length;
  }

  Group copyWith({
    String? title,
    String? ownerId,
    List<String>? memberIds,
    int? memberCount,
    List<String?>? slotOwnerIds,
  }) {
    return Group(
      id: id,
      title: title ?? this.title,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      slotOwnerIds: slotOwnerIds ?? this.slotOwnerIds,
      post: post,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'memberCount': memberCount,
      'slotOwnerIds': effectiveSlotOwnerIds,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Group.fromMap(String docId, Map<String, dynamic> map) {
    final memberIds = List<String>.from(map['memberIds'] ?? []);
    final memberCount =
        (map['memberCount'] as num?)?.toInt() ??
        (map['memberLimit'] as num?)?.toInt() ??
        memberIds.length;
    final rawSlotOwnerIds = map['slotOwnerIds'] as List<dynamic>?;
    final slotOwnerIds =
        rawSlotOwnerIds
            ?.map((value) => value == null ? null : value as String)
            .toList() ??
        List<String?>.generate(
          memberCount,
          (index) => index < memberIds.length ? memberIds[index] : null,
        );

    return Group(
      id: docId,
      title: map['title'] ?? '',
      ownerId: map['ownerId'] ?? '',
      memberIds: memberIds,
      memberCount: memberCount,
      slotOwnerIds: slotOwnerIds,
    );
  }
}
