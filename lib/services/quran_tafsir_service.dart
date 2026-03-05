import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class QuranAyahTafsir {
  const QuranAyahTafsir({
    required this.verseKey,
    required this.resourceId,
    required this.resourceName,
    required this.text,
    required this.fromOfflineCache,
  });

  final String verseKey;
  final int resourceId;
  final String resourceName;
  final String text;
  final bool fromOfflineCache;
}

class QuranTafsirService {
  QuranTafsirService({Dio? dio, BaseCacheManager? cacheManager})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.quran.com/api/v4',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 15),
              responseType: ResponseType.json,
            ),
          ),
      _cacheManager = cacheManager ?? DefaultCacheManager();

  static const List<int> _preferredBanglaTafsirIds = [166, 165, 164, 381];
  static const _tafsirCachePrefix = 'quran_tafsir_v1';
  final Dio _dio;
  final BaseCacheManager _cacheManager;
  final Map<String, QuranAyahTafsir> _memoryCache = {};

  String _cacheKey(String verseKey) => '${_tafsirCachePrefix}_$verseKey';

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Invalid response map format.');
  }

  String _stripHtml(String rawHtml) {
    var text = rawHtml
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<li>', caseSensitive: false), '- ')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    text = text.replaceAll(RegExp(r'\r\n?'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    return text.trim();
  }

  Future<void> _saveToCache(QuranAyahTafsir tafsir) async {
    final key = _cacheKey(tafsir.verseKey);
    final payload = jsonEncode({
      'verse_key': tafsir.verseKey,
      'resource_id': tafsir.resourceId,
      'resource_name': tafsir.resourceName,
      'text': tafsir.text,
    });

    await _cacheManager.putFile(
      key,
      Uint8List.fromList(utf8.encode(payload)),
      key: key,
      fileExtension: 'json',
    );
  }

  Future<QuranAyahTafsir?> _readFromCache(String verseKey) async {
    final key = _cacheKey(verseKey);
    final cached = await _cacheManager.getFileFromCache(key);
    if (cached == null || !await cached.file.exists()) return null;

    try {
      final parsed = jsonDecode(await cached.file.readAsString());
      if (parsed is! Map) return null;
      final map = Map<String, dynamic>.from(parsed);
      final text = (map['text'] ?? '').toString().trim();
      if (text.isEmpty) return null;

      return QuranAyahTafsir(
        verseKey: (map['verse_key'] ?? verseKey).toString(),
        resourceId: (map['resource_id'] as num?)?.toInt() ?? 0,
        resourceName: (map['resource_name'] ?? 'Bangla Tafsir').toString(),
        text: text,
        fromOfflineCache: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<QuranAyahTafsir> fetchBanglaTafsir({
    required int surahNo,
    required int ayahNo,
  }) async {
    final verseKey = '$surahNo:$ayahNo';
    final memoryCached = _memoryCache[verseKey];
    if (memoryCached != null) return memoryCached;

    final diskCached = await _readFromCache(verseKey);
    if (diskCached != null) {
      _memoryCache[verseKey] = diskCached;
      return diskCached;
    }

    for (final resourceId in _preferredBanglaTafsirIds) {
      try {
        final response = await _dio.get(
          '/tafsirs/$resourceId/by_ayah/$verseKey',
        );
        final root = _asMap(response.data);
        final tafsir = _asMap(root['tafsir']);
        final rawText = (tafsir['text'] ?? '').toString();
        final cleanedText = _stripHtml(rawText);
        if (cleanedText.isEmpty) continue;

        final data = QuranAyahTafsir(
          verseKey: verseKey,
          resourceId: resourceId,
          resourceName: (tafsir['resource_name'] ?? 'Bangla Tafsir').toString(),
          text: cleanedText,
          fromOfflineCache: false,
        );
        _memoryCache[verseKey] = data;
        await _saveToCache(data);
        return data;
      } catch (_) {
        // Try the next Bangla tafsir source.
      }
    }

    throw Exception('Bangla tafsir is not available right now.');
  }
}
