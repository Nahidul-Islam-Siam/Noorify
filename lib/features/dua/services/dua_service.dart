import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:first_project/features/dua/models/dua_item.dart';

class DuaService {
  static const assetPath = 'assets/data/duas.json';

  Future<List<DuaItem>> loadDuas() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Dua dataset must be a JSON list.');
      }

      final output = <DuaItem>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final dua = DuaItem.fromJson(Map<String, dynamic>.from(item));
        if (!dua.isActive) continue;
        output.add(dua);
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
