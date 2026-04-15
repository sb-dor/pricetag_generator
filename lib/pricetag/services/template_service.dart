import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../designer/models/canvas_element.dart';
import '../designer/models/label_size.dart';
import '../designer/notifiers/canvas_notifier.dart';

class TemplateModel {
  final String name;
  final LabelSize labelSize;
  final List<CanvasElement> elements;
  final DateTime savedAt;

  const TemplateModel({
    required this.name,
    required this.labelSize,
    required this.elements,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'savedAt': savedAt.toIso8601String(),
    'labelSize': labelSize.toJson(),
    'elements': elements.map((e) => e.toJson()).toList(),
  };

  factory TemplateModel.fromJson(Map<String, dynamic> json) => TemplateModel(
    name: json['name'] as String,
    savedAt: DateTime.parse(json['savedAt'] as String),
    labelSize: LabelSize.fromJson(json['labelSize'] as Map<String, dynamic>),
    elements: (json['elements'] as List)
        .map((e) => CanvasElement.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class TemplateService {
  static const _key = 'pricetag_templates';

  /// Save the current canvas state as a named template.
  Future<void> save(CanvasNotifier notifier, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final templates = await loadAll();

    // Replace existing template with same name if exists
    templates.removeWhere((t) => t.name == name);
    templates.add(
      TemplateModel(
        name: name,
        labelSize: notifier.labelSize,
        elements: List.of(notifier.elements),
        savedAt: DateTime.now(),
      ),
    );

    final json = jsonEncode(templates.map((t) => t.toJson()).toList());
    await prefs.setString(_key, json);
  }

  /// Load all saved templates.
  Future<List<TemplateModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => TemplateModel.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  /// Apply a template to the canvas notifier.
  void apply(TemplateModel template, CanvasNotifier notifier) {
    notifier.clear();
    notifier.setLabelSize(template.labelSize);
    for (final element in template.elements) {
      notifier.addElement(element);
    }
    notifier.selectElement(null);
  }

  /// Delete a template by name.
  Future<void> delete(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final templates = await loadAll();
    templates.removeWhere((t) => t.name == name);
    await prefs.setString(_key, jsonEncode(templates.map((t) => t.toJson()).toList()));
  }
}
