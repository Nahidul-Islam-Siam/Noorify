import 'dart:convert';
import 'dart:io';

const String _inputPath = 'assets/data/hadith_bukhari_50.json';
const String _updatedAt = '2026-03-07T00:00:00Z';

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Expected map item in JSON list.');
}

Future<String> _translateEnToBn(String text) async {
  final normalized = text.trim();
  if (normalized.isEmpty) return '';

  final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
    'client': 'gtx',
    'sl': 'en',
    'tl': 'bn',
    'dt': 't',
    'q': normalized,
  });

  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Translate API status ${response.statusCode}',
        uri: uri,
      );
    }

    final raw = utf8.decode(
      await response.fold<List<int>>(
        <int>[],
        (buffer, bytes) => buffer..addAll(bytes),
      ),
    );
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.isEmpty || decoded[0] is! List) {
      throw const FormatException('Unexpected translate API response format.');
    }

    final parts = decoded[0] as List<dynamic>;
    final out = StringBuffer();
    for (final part in parts) {
      if (part is List && part.isNotEmpty && part[0] != null) {
        out.write(part[0].toString());
      }
    }
    return out.toString().trim();
  } finally {
    client.close(force: true);
  }
}

Future<String> _translateWithRetry(String text) async {
  const maxAttempts = 3;
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await _translateEnToBn(text);
    } catch (_) {
      if (attempt == maxAttempts) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
    }
  }
  return '';
}

Future<void> main() async {
  final file = File(_inputPath);
  if (!await file.exists()) {
    stderr.writeln('Dataset not found: $_inputPath');
    exitCode = 1;
    return;
  }

  try {
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Hadith dataset must be a JSON list.');
    }

    final updated = <Map<String, dynamic>>[];
    int translatedCount = 0;

    for (int i = 0; i < decoded.length; i++) {
      final item = _toMap(decoded[i]);
      final id = (item['id'] as num?)?.toInt() ?? (i + 1);

      final titleEn = (item['title_en'] ?? '').toString();
      final banglaSource = (item['english'] ?? '').toString();

      final currentTitleBn = (item['title_bn'] ?? '').toString().trim();
      final currentBangla = (item['bangla'] ?? '').toString().trim();

      String titleBn = currentTitleBn;
      String bangla = currentBangla;

      if (titleBn.isEmpty) {
        titleBn = await _translateWithRetry(titleEn);
        await Future<void>.delayed(const Duration(milliseconds: 130));
      }
      if (bangla.isEmpty) {
        bangla = await _translateWithRetry(banglaSource);
        await Future<void>.delayed(const Duration(milliseconds: 130));
      }

      if (titleBn.isNotEmpty || bangla.isNotEmpty) {
        translatedCount += 1;
      }

      item['title_bn'] = titleBn;
      item['bangla'] = bangla;
      item['updated_at'] = _updatedAt;
      updated.add(item);

      stdout.writeln('[$id/${decoded.length}] translated');
    }

    final out = const JsonEncoder.withIndent('  ').convert(updated);
    await file.writeAsString('$out\n');
    stdout.writeln(
      'Updated Bangla fields for $translatedCount entries in ${file.path}',
    );
  } catch (e) {
    stderr.writeln('Failed to fill Bangla hadith translation: $e');
    exitCode = 1;
  }
}
