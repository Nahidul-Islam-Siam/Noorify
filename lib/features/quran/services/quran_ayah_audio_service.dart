import 'package:dio/dio.dart';

class QuranAyahAudioService {
  QuranAyahAudioService({Dio? dio})
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
          );

  final Dio _dio;

  static const _audioCdnBase = 'https://verses.quran.com/';
  static const List<int> _fallbackRecitationIds = [7, 4, 5];

  String _toAbsoluteUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return '$_audioCdnBase$trimmed';
  }

  List<int> _candidateRecitationIds(int? preferredRecitationId) {
    final ids = <int>[];
    if (preferredRecitationId != null && preferredRecitationId > 0) {
      ids.add(preferredRecitationId);
    }
    for (final id in _fallbackRecitationIds) {
      if (!ids.contains(id)) ids.add(id);
    }
    return ids;
  }

  Future<String> fetchAyahAudioUrl({
    required int surahNo,
    required int ayahNo,
    int? preferredRecitationId,
  }) async {
    final verseKey = '$surahNo:$ayahNo';

    for (final recitationId in _candidateRecitationIds(preferredRecitationId)) {
      try {
        final response = await _dio.get(
          '/recitations/$recitationId/by_ayah/$verseKey',
        );
        final root = response.data;
        if (root is! Map) continue;
        final audioFiles = root['audio_files'];
        if (audioFiles is! List || audioFiles.isEmpty) continue;
        final first = audioFiles.first;
        if (first is! Map) continue;

        final rawUrl = (first['url'] ?? '').toString();
        final resolved = _toAbsoluteUrl(rawUrl);
        if (resolved.isNotEmpty) return resolved;
      } catch (_) {
        // Try the next recitation ID.
      }
    }

    throw Exception('No ayah audio URL found.');
  }
}
