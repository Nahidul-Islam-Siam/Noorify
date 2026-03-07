import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'package:first_project/features/asmaul_husna/models/asma_name.dart';

class AsmaService {
  AsmaService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.aladhan.com',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              responseType: ResponseType.json,
            ),
          );

  static const assetPath = 'assets/data/asmaul_husna.json';

  final Dio _dio;

  Map<String, dynamic> _asStringDynamicMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Invalid map format.');
  }

  Future<List<AsmaName>> fetchAsmaNamesFromApi() async {
    try {
      final response = await _dio.get('/v1/asmaAlHusna');
      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw Exception('Unexpected status code: $statusCode');
      }

      final body = _asStringDynamicMap(response.data);
      final data = body['data'];
      if (data is! List) {
        throw const FormatException(
          'Asma API response is missing a valid data list.',
        );
      }

      final output = <AsmaName>[];
      for (final item in data) {
        final map = _asStringDynamicMap(item);
        final id = (map['number'] as num?)?.toInt() ?? 0;
        final english = map['en'];
        final englishMap = english is Map<String, dynamic>
            ? english
            : (english is Map ? Map<String, dynamic>.from(english) : null);

        if (id <= 0) continue;
        output.add(
          AsmaName(
            id: id,
            arabic: (map['name'] ?? '').toString(),
            transliteration: (map['transliteration'] ?? '').toString(),
            englishMeaning: (englishMap?['meaning'] ?? '').toString(),
            banglaName: '',
            banglaMeaning: '',
            audio: null,
          ),
        );
      }

      output.sort((a, b) => a.id.compareTo(b.id));
      return output;
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch Asmaul Husna. Network/API error: ${e.message}',
      );
    } on FormatException catch (e) {
      throw Exception('Failed to parse Asmaul Husna response: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch Asmaul Husna: $e');
    }
  }

  Future<List<AsmaName>> loadAsmaNames() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Local Asma dataset must be a JSON list.');
      }

      final output = <AsmaName>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        output.add(AsmaName.fromJson(Map<String, dynamic>.from(item)));
      }
      return output;
    } on FormatException catch (e) {
      throw Exception('Failed to parse $assetPath: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load $assetPath: $e');
    }
  }

  List<Map<String, dynamic>> toJsonList(List<AsmaName> names) {
    return names.map((item) => item.toJson()).toList(growable: false);
  }

  String toJsonString(List<AsmaName> names, {bool pretty = false}) {
    final list = toJsonList(names);
    if (pretty) return const JsonEncoder.withIndent('  ').convert(list);
    return jsonEncode(list);
  }
}
