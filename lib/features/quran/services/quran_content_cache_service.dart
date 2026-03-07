import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:first_project/features/quran/models/quran_models.dart';

class QuranContentCacheService {
  QuranContentCacheService({BaseCacheManager? cacheManager})
    : _cacheManager = cacheManager ?? DefaultCacheManager();

  static const _chaptersCacheKey = 'quran_chapters_v1';
  static const _surahCachePrefix = 'quran_surah_v1';

  final BaseCacheManager _cacheManager;

  String _surahCacheKey(int surahNo, {String lang = 'bn'}) =>
      '$_surahCachePrefix-${lang}_$surahNo';

  Future<void> _putJson(String key, Object jsonObject) async {
    final jsonString = jsonEncode(jsonObject);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    await _cacheManager.putFile(key, bytes, key: key, fileExtension: 'json');
  }

  Future<Object?> _readJson(String key) async {
    final cached = await _cacheManager.getFileFromCache(key);
    if (cached == null || !await cached.file.exists()) return null;

    try {
      final text = await cached.file.readAsString();
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveChaptersRaw(List<dynamic> rawData) async {
    await _putJson(_chaptersCacheKey, rawData);
  }

  Future<List<QuranChapter>?> readChapters() async {
    final decoded = await _readJson(_chaptersCacheKey);
    if (decoded is! List) return null;

    final chapters = <QuranChapter>[];
    for (var i = 0; i < decoded.length; i++) {
      final item = decoded[i];
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      chapters.add(QuranChapter.fromJson(map, index: i + 1));
    }
    return chapters.isEmpty ? null : chapters;
  }

  Future<void> saveSurahDetailRaw(
    int surahNo,
    Map<String, dynamic> rawData, {
    String lang = 'bn',
  }) async {
    await _putJson(_surahCacheKey(surahNo, lang: lang), rawData);
  }

  Future<QuranSurahDetail?> readSurahDetail(
    int surahNo, {
    String lang = 'bn',
  }) async {
    final decoded = await _readJson(_surahCacheKey(surahNo, lang: lang));
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);
    return QuranSurahDetail.fromJson(map);
  }
}
