import 'package:dio/dio.dart';

import '../models/quran_models.dart';

class QuranApiService {
  QuranApiService({Dio? dio})
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
          );

  final Dio _dio;

  Future<List<QuranChapter>> fetchChapters() async {
    final response = await _dio.get('/api/surah.json');
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Unexpected chapter list response format.');
    }

    return data
        .asMap()
        .entries
        .map((entry) {
          final value = entry.value;
          if (value is! Map<String, dynamic>) {
            throw const FormatException('Invalid chapter entry format.');
          }
          return QuranChapter.fromJson(value, index: entry.key + 1);
        })
        .toList(growable: false);
  }

  Future<QuranSurahDetail> fetchSurahDetail(
    int surahNo, {
    String lang = 'bn',
  }) async {
    final response = await _dio.get(
      '/api/$surahNo.json',
      queryParameters: {'lang': lang},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected surah response format.');
    }
    return QuranSurahDetail.fromJson(data);
  }

  Future<List<QuranReciterAudio>> fetchSurahAudios(int surahNo) async {
    final response = await _dio.get('/api/audio/$surahNo.json');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected audio response format.');
    }

    final list = <QuranReciterAudio>[];
    for (final entry in data.entries) {
      final id = int.tryParse(entry.key);
      final value = entry.value;
      if (id == null || value is! Map<String, dynamic>) continue;
      list.add(QuranReciterAudio.fromJson(id, value));
    }
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }
}
