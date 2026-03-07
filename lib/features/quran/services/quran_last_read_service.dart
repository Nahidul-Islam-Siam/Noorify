import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class QuranLastReadService {
  QuranLastReadService({BaseCacheManager? cacheManager})
    : _cacheManager = cacheManager ?? DefaultCacheManager();

  static const _cacheKey = 'quran_last_read_v1';
  final BaseCacheManager _cacheManager;

  Future<void> saveLastReadSurahNo(int surahNo) async {
    final payload = jsonEncode({'surahNo': surahNo});
    await _cacheManager.putFile(
      _cacheKey,
      Uint8List.fromList(utf8.encode(payload)),
      key: _cacheKey,
      fileExtension: 'json',
    );
  }

  Future<int?> readLastReadSurahNo() async {
    final cached = await _cacheManager.getFileFromCache(_cacheKey);
    if (cached == null || !await cached.file.exists()) return null;

    try {
      final raw = await cached.file.readAsString();
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final value = json['surahNo'];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    } catch (_) {
      return null;
    }
  }
}
