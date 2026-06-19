import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:bababam_app/Model/post.dart';

class TodayGroupVideoCacheService {
  TodayGroupVideoCacheService({this.onControllerReady});

  final void Function()? onControllerReady;
  String? _activeDayKey;
  double _volume = 0;
  final Set<String> _queuedDownloadUrls = <String>{};
  final Map<String, CachedVideoPlayerPlusController> _controllerPool = {};
  final Map<String, double> _volumeByUrl = {};
  Future<void> _downloadChain = Future<void>.value();
  Future<void> _controllerChain = Future<void>.value();
  final _cacheManager = DefaultCacheManager();

  Future<void> prepareForDay(String dayKey) async {
    if (_activeDayKey == dayKey) return;

    _activeDayKey = dayKey;
    _queuedDownloadUrls.clear();
    _volumeByUrl.clear();
    for (final controller in _controllerPool.values) {
      await controller.dispose();
    }
    _controllerPool.clear();
  }

  void warmPosts(List<Post> posts) {
    final urls = posts
        .map((p) => p.videoUrl)
        .where(
          (url) =>
              (url.startsWith('http://') || url.startsWith('https://')) &&
              !_queuedDownloadUrls.contains(url),
        )
        .toList();

    if (urls.isEmpty) return;
    _queuedDownloadUrls.addAll(urls);

    _downloadChain = _downloadChain.then((_) async {
      for (final url in urls) {
        try {
          await _cacheManager.getFileFromCache(url) ??
              await _cacheManager.downloadFile(url);
        } catch (_) {}
      }
    });
  }

  void prepareControllersForPosts(
    List<Post> posts, {
    required Set<String> activeVideoUrls,
  }) {
    final keepUrls = posts
        .map((p) => p.videoUrl)
        .where((url) => url.startsWith('http://') || url.startsWith('https://'))
        .toSet();

    _controllerChain = _controllerChain.then((_) async {
      final removableUrls = _controllerPool.keys
          .where((url) => !keepUrls.contains(url))
          .toList();
      for (final url in removableUrls) {
        final controller = _controllerPool.remove(url);
        await controller?.dispose();
      }

      for (final url in keepUrls) {
        final existing = _controllerPool[url];
        if (existing != null && existing.value.isInitialized) continue;

        try {
          final cachedFile =
              await _cacheManager.getFileFromCache(url) ??
              await _cacheManager.downloadFile(url);
          final controller = CachedVideoPlayerPlusController.file(
            cachedFile.file,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
          _controllerPool[url] = controller;
          await controller.initialize();
          await controller.setLooping(true);
          await controller.setVolume(_volumeByUrl[url] ?? _volume);
          onControllerReady?.call();
        } catch (_) {
          final failedController = _controllerPool.remove(url);
          await failedController?.dispose();
        }
      }

      for (final entry in _controllerPool.entries) {
        final controller = entry.value;
        if (!controller.value.isInitialized) continue;

        if (activeVideoUrls.contains(entry.key)) {
          await controller.play();
        } else {
          await controller.pause();
        }
      }
    });
  }

  CachedVideoPlayerPlusController? controllerFor(String url) {
    final controller = _controllerPool[url];
    if (controller == null) return null;
    if (!controller.value.isInitialized) return null;
    return controller;
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0, 1).toDouble();
    for (final controller in _controllerPool.values) {
      if (!controller.value.isInitialized) continue;
      await controller.setVolume(_volume);
    }
  }

  Future<void> setVolumeForUrl(String url, double volume) async {
    final normalizedVolume = volume.clamp(0, 1).toDouble();
    _volumeByUrl[url] = normalizedVolume;

    final controller = _controllerPool[url];
    if (controller == null || !controller.value.isInitialized) return;
    await controller.setVolume(normalizedVolume);
  }

  Future<void> disposeAll() async {
    for (final controller in _controllerPool.values) {
      await controller.dispose();
    }
    _controllerPool.clear();
  }
}
