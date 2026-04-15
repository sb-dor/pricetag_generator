import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receipt_template.dart';

class TemplateStorage {
  static const _key = 'receipt_templates';

  Future<List<ReceiptTemplate>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => ReceiptTemplate.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveAll(List<ReceiptTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(templates.map((t) => t.toJson()).toList()));
  }
}
