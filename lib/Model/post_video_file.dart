class PostVideoFile {
  const PostVideoFile({this.videoUrl, this.storagePath});

  final String? videoUrl;
  final String? storagePath;

  bool get hasReference {
    return (videoUrl != null && videoUrl!.isNotEmpty) ||
        (storagePath != null && storagePath!.isNotEmpty);
  }
}
