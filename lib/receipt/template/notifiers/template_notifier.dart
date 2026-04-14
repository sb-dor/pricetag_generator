import 'package:flutter/foundation.dart';
import '../models/receipt_block.dart';
import '../models/receipt_template.dart';
import '../services/template_storage.dart';

class TemplateNotifier extends ChangeNotifier {
  final TemplateStorage _storage = TemplateStorage();

  List<ReceiptTemplate> _templates = [];
  ReceiptTemplate _editing = ReceiptTemplate.defaultTemplate;

  List<ReceiptTemplate> get templates => List.unmodifiable(_templates);
  ReceiptTemplate get editing => _editing;

  Future<void> load() async {
    _templates = await _storage.loadAll();
    // Ensure default template always present
    if (!_templates.any((t) => t.id == 'default')) {
      _templates.insert(0, ReceiptTemplate.defaultTemplate);
    }
    notifyListeners();
  }

  void startEditing(ReceiptTemplate template) {
    // Deep-copy blocks so we can discard changes
    _editing = ReceiptTemplate(
      id: template.id,
      name: template.name,
      paperWidthMm: template.paperWidthMm,
      blocks: template.blocks.toList(),
    );
    notifyListeners();
  }

  void setEditingPaperWidth(int mm) {
    _editing = _editing.copyWith(paperWidthMm: mm);
    notifyListeners();
  }

  void setEditingName(String name) {
    _editing = _editing.copyWith(name: name);
    notifyListeners();
  }

  void reorderBlocks(int oldIndex, int newIndex) {
    final blocks = _editing.blocks.toList();
    if (newIndex > oldIndex) newIndex--;
    final item = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, item);
    _editing = _editing.copyWith(blocks: blocks);
    notifyListeners();
  }

  void toggleBlockVisible(int index) {
    final blocks = _editing.blocks.toList();
    blocks[index].visible = !blocks[index].visible;
    _editing = _editing.copyWith(blocks: blocks);
    notifyListeners();
  }

  void updateBlock(int index, ReceiptBlock updated) {
    final blocks = _editing.blocks.toList();
    blocks[index] = updated;
    _editing = _editing.copyWith(blocks: blocks);
    notifyListeners();
  }

  void addBlock(ReceiptBlock block) {
    final blocks = [..._editing.blocks, block];
    _editing = _editing.copyWith(blocks: blocks);
    notifyListeners();
  }

  void removeBlock(int index) {
    final blocks = _editing.blocks.toList()..removeAt(index);
    _editing = _editing.copyWith(blocks: blocks);
    notifyListeners();
  }

  Future<void> saveEditing() async {
    final i = _templates.indexWhere((t) => t.id == _editing.id);
    if (i != -1) {
      _templates[i] = _editing;
    } else {
      _templates.add(_editing);
    }
    await _storage.saveAll(_templates.where((t) => t.id != 'default').toList());
    notifyListeners();
  }

  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    await _storage.saveAll(_templates.where((t) => t.id != 'default').toList());
    notifyListeners();
  }
}
