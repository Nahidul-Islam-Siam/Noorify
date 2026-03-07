import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:first_project/features/hadith/models/hadith_item.dart';

class HadithService {
  static const assetPath = 'assets/data/hadith_bukhari_50.json';

  Future<List<HadithItem>> loadHadiths() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Hadith dataset must be a JSON list.');
      }

      final output = <HadithItem>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final hadith = HadithItem.fromJson(Map<String, dynamic>.from(item));
        if (!hadith.isActive) continue;
        output.add(hadith);
      }

      output.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return output;
    } on FormatException catch (e) {
      throw Exception('Failed to parse $assetPath: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load $assetPath: $e');
    }
  }
}
