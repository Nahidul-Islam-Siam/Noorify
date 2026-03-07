import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class QuranOfflineDownloadService {
  QuranOfflineDownloadService({BaseCacheManager? cacheManager})
    : _cacheManager = cacheManager ?? DefaultCacheManager();

  final BaseCacheManager _cacheManager;

  Future<String> downloadAudio(String mp3Url) async {
    final uri = Uri.tryParse(mp3Url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      throw ArgumentError('Invalid audio URL.');
    }

    final file = await _cacheManager.getSingleFile(mp3Url);
    return file.path;
  }

  Future<bool> hasAudio(String mp3Url) async {
    final cached = await _cacheManager.getFileFromCache(mp3Url);
    return cached != null && await cached.file.exists();
  }

  Future<File?> getCachedAudio(String mp3Url) async {
    final cached = await _cacheManager.getFileFromCache(mp3Url);
    if (cached == null) return null;
    if (!await cached.file.exists()) return null;
    return cached.file;
  }
}
