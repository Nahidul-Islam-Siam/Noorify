import 'dart:convert';
import 'dart:io';

const String _sourceUrl =
    'https://raw.githubusercontent.com/AhmedBaset/hadith-json/main/db/by_book/the_9_books/bukhari.json';
const String _outputPath = 'assets/data/hadith_bukhari_50.json';
const int _targetCount = 50;
const String _updatedAt = '2026-03-07T00:00:00Z';

String _clean(String input) {
  return input.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _slugify(String input) {
  final lower = input.toLowerCase();
  final slug = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  final compact = slug.replaceAll(RegExp(r'_+'), '_');
  return compact.replaceAll(RegExp(r'^_|_$'), '');
}

String _titleFromText(String englishText) {
  final text = _clean(englishText);
  if (text.isEmpty) return 'Selected Hadith';

  final sentenceEnd = text.indexOf(RegExp(r'[.!?]'));
  final title = sentenceEnd > 0 ? text.substring(0, sentenceEnd + 1) : text;
  if (title.length <= 86) return title;
  return '${title.substring(0, 83).trimRight()}...';
}

bool _isWithinPreferredLength(String value) {
  final len = value.length;
  return len >= 80 && len <= 520;
}

Future<String> _downloadSourceJson() async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(_sourceUrl));
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed with status code ${response.statusCode}',
        uri: Uri.parse(_sourceUrl),
      );
    }

    return utf8.decode(
      await response.fold<List<int>>(
        <int>[],
        (previous, element) => previous..addAll(element),
      ),
    );
  } finally {
    client.close(force: true);
  }
}

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Expected a map object.');
}

Future<void> main() async {
  try {
    final raw = await _downloadSourceJson();
    final decoded = jsonDecode(raw);
    final root = _toMap(decoded);

    final chaptersRaw = root['chapters'];
    final hadithsRaw = root['hadiths'];
    if (chaptersRaw is! List || hadithsRaw is! List) {
      throw const FormatException('Source JSON is missing chapters/hadiths.');
    }

    final chapterById = <int, String>{};
    for (final chapter in chaptersRaw) {
      final map = _toMap(chapter);
      final id = (map['id'] as num?)?.toInt() ?? 0;
      if (id <= 0) continue;
      final englishTitle = _clean((map['english'] ?? '').toString());
      chapterById[id] = englishTitle.isEmpty ? 'General' : englishTitle;
    }

    final output = <Map<String, dynamic>>[];
    final usedSourceIds = <int>{};

    void addIfValid(Map<String, dynamic> hadith, {required bool strictLength}) {
      if (output.length >= _targetCount) return;

      final sourceId = (hadith['id'] as num?)?.toInt() ?? 0;
      final idInBook = (hadith['idInBook'] as num?)?.toInt() ?? sourceId;
      final chapterId = (hadith['chapterId'] as num?)?.toInt() ?? 0;
      final arabic = _clean((hadith['arabic'] ?? '').toString());
      if (sourceId <= 0 || arabic.isEmpty || usedSourceIds.contains(sourceId)) {
        return;
      }

      final englishObj = hadith['english'];
      final englishMap = englishObj is Map<String, dynamic>
          ? englishObj
          : (englishObj is Map ? Map<String, dynamic>.from(englishObj) : null);

      final narrator = _clean((englishMap?['narrator'] ?? '').toString());
      final englishText = _clean((englishMap?['text'] ?? '').toString());
      final english = [
        narrator,
        englishText,
      ].where((part) => part.isNotEmpty).join(' ').trim();
      if (english.isEmpty) return;
      if (strictLength && !_isWithinPreferredLength(english)) return;

      final chapterEn = chapterById[chapterId] ?? 'General';
      final category = _slugify(chapterEn).isEmpty
          ? 'general'
          : _slugify(chapterEn);
      final itemIndex = output.length + 1;

      output.add({
        'id': itemIndex,
        'uid': 'bukhari_${itemIndex.toString().padLeft(4, '0')}',
        'source_hadith_id': sourceId,
        'category': category,
        'title_en': _titleFromText(englishText.isEmpty ? english : englishText),
        'title_bn': '',
        'arabic': arabic,
        'english': english,
        'bangla': '',
        'reference': 'Sahih al-Bukhari, Hadith $idInBook',
        'audio': null,
        'content_version': 1,
        'updated_at': _updatedAt,
        'is_active': true,
        'sort_order': itemIndex,
      });
      usedSourceIds.add(sourceId);
    }

    for (final entry in hadithsRaw) {
      if (output.length >= _targetCount) break;
      final map = _toMap(entry);
      addIfValid(map, strictLength: true);
    }

    // Fallback fill in case strict length filtering produced fewer records.
    if (output.length < _targetCount) {
      for (final entry in hadithsRaw) {
        if (output.length >= _targetCount) break;
        final map = _toMap(entry);
        addIfValid(map, strictLength: false);
      }
    }

    if (output.length < _targetCount) {
      throw Exception(
        'Only generated ${output.length} hadith entries (expected $_targetCount).',
      );
    }

    final file = File(_outputPath);
    await file.parent.create(recursive: true);
    final json = const JsonEncoder.withIndent('  ').convert(output);
    await file.writeAsString('$json\n');

    stdout.writeln('Saved ${output.length} hadith entries to ${file.path}');
  } catch (e) {
    stderr.writeln('Failed to generate Bukhari hadith dataset: $e');
    exitCode = 1;
  }
}
