import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:first_project/models/asma_name.dart';

Future<List<AsmaName>> fetchAsmaNames() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.aladhan.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );

  final response = await dio.get('/v1/asmaAlHusna');
  final statusCode = response.statusCode ?? 0;
  if (statusCode < 200 || statusCode >= 300) {
    throw Exception('Unexpected status code: $statusCode');
  }

  final data = response.data;
  if (data is! Map) {
    throw const FormatException('Invalid API response map.');
  }

  final list = data['data'];
  if (list is! List) {
    throw const FormatException('Invalid API response list.');
  }

  final output = <AsmaName>[];
  for (final item in list) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final id = (map['number'] as num?)?.toInt() ?? 0;
    if (id <= 0) continue;

    final en = map['en'];
    final enMap = en is Map<String, dynamic>
        ? en
        : (en is Map ? Map<String, dynamic>.from(en) : null);

    output.add(
      AsmaName(
        id: id,
        arabic: (map['name'] ?? '').toString(),
        transliteration: (map['transliteration'] ?? '').toString(),
        englishMeaning: (enMap?['meaning'] ?? '').toString(),
        banglaName: '',
        banglaMeaning: '',
        audio: null,
      ),
    );
  }

  output.sort((a, b) => a.id.compareTo(b.id));
  return output;
}

String asmaNamesToJson(List<AsmaName> names) {
  final list = names.map((item) => item.toJson()).toList(growable: false);
  return jsonEncode(list);
}

Future<void> main() async {
  try {
    final names = await fetchAsmaNames();
    if (names.isEmpty) {
      throw Exception('No Asma data received from API.');
    }

    final file = File('assets/data/asmaul_husna.json');
    await file.parent.create(recursive: true);

    final payload = '${asmaNamesToJson(names)}\n';
    await file.writeAsString(payload);

    stdout.writeln('Saved ${names.length} names to ${file.path}');
  } catch (e) {
    stderr.writeln('Failed to generate Asma dataset: $e');
    exitCode = 1;
  }
}
