import 'package:flutter/services.dart';

class PostVideoTransformService {
  const PostVideoTransformService();

  static const MethodChannel _channel = MethodChannel(
    'slott/post_video_transform',
  );

  Future<String> exportLandscapeCopy(String inputPath) async {
    final outputPath = await _channel.invokeMethod<String>(
      'exportLandscapeCopy',
      {'inputPath': inputPath},
    );

    if (outputPath == null || outputPath.isEmpty) {
      throw StateError('Landscape video export returned an empty path.');
    }

    return outputPath;
  }
}
