import 'package:dio/dio.dart';

import 'package:first_project/features/quran/models/quran_models.dart';
import 'quran_content_cache_service.dart';

class QuranApiService {
  QuranApiService({Dio? dio, QuranContentCacheService? cacheService})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://quranapi.pages.dev',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              responseType: ResponseType.json,
            ),
          ),
      _cacheService = cacheService ?? QuranContentCacheService();

  final Dio _dio;
  final QuranContentCacheService _cacheService;

  bool _lastReadFromCache = false;
  bool get lastReadFromCache => _lastReadFromCache;

  Map<String, dynamic> _asStringDynamicMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Invalid map format.');
  }

  Future<List<QuranChapter>> fetchChapters() async {
    _lastReadFromCache = false;
    try {
      final response = await _dio.get('/api/surah.json');
      final data = response.data;
      if (data is! List) {
        throw const FormatException('Unexpected chapter list response format.');
      }

      final chapters = data
          .asMap()
          .entries
          .map((entry) {
            final value = entry.value;
            return QuranChapter.fromJson(
              _asStringDynamicMap(value),
              index: entry.key + 1,
            );
          })
          .toList(growable: false);

      await _cacheService.saveChaptersRaw(data);
      return chapters;
    } catch (_) {
      final cached = await _cacheService.readChapters();
      if (cached != null && cached.isNotEmpty) {
        _lastReadFromCache = true;
        return cached;
      }
      rethrow;
    }
  }

  Future<QuranSurahDetail> fetchSurahDetail(
    int surahNo, {
    String lang = 'bn',
  }) async {
    _lastReadFromCache = false;
    try {
      final response = await _dio.get(
        '/api/$surahNo.json',
        queryParameters: {'lang': lang},
      );
      final data = response.data;
      final map = _asStringDynamicMap(data);
      final detail = QuranSurahDetail.fromJson(map);
      await _cacheService.saveSurahDetailRaw(surahNo, map, lang: lang);
      return detail;
    } catch (_) {
      final cached = await _cacheService.readSurahDetail(surahNo, lang: lang);
      if (cached != null) {
        _lastReadFromCache = true;
        return cached;
      }
      rethrow;
    }
  }

  Future<List<QuranReciterAudio>> fetchSurahAudios(int surahNo) async {
    _lastReadFromCache = false;
    try {
      final response = await _dio.get('/api/audio/$surahNo.json');
      final data = response.data;
      if (data is! Map) {
        throw const FormatException('Unexpected audio response format.');
      }

      final list = <QuranReciterAudio>[];
      for (final entry in data.entries) {
        final id = int.tryParse(entry.key.toString());
        final value = entry.value;
        if (id == null || value is! Map) continue;
        list.add(
          QuranReciterAudio.fromJson(id, Map<String, dynamic>.from(value)),
        );
      }
      list.sort((a, b) => a.id.compareTo(b.id));
      return list;
    } catch (_) {
      final cached = await _cacheService.readSurahDetail(surahNo, lang: 'bn');
      if (cached != null && cached.audioByReciter.isNotEmpty) {
        _lastReadFromCache = true;
        return cached.audioByReciter;
      }
      rethrow;
    }
  }
}
