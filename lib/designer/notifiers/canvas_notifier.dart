import 'package:flutter/foundation.dart';
import '../models/canvas_element.dart';
import '../models/label_size.dart';

class CanvasNotifier extends ChangeNotifier {
  LabelSize _labelSize = LabelSize.presets.first;
  final List<CanvasElement> _elements = [];
  String? _selectedId;

  LabelSize get labelSize => _labelSize;
  List<CanvasElement> get elements => List.unmodifiable(_elements);
  String? get selectedId => _selectedId;

  CanvasElement? get selectedElement =>
      _selectedId == null ? null : _elements.where((e) => e.id == _selectedId).firstOrNull;

  // ── Label size ────────────────────────────────────────────────────────────

  void setLabelSize(LabelSize size) {
    _labelSize = size;
    notifyListeners();
  }

  // ── Elements ──────────────────────────────────────────────────────────────

  void addElement(CanvasElement element) {
    _elements.add(element);
    _selectedId = element.id;
    notifyListeners();
  }

  void removeElement(String id) {
    _elements.removeWhere((e) => e.id == id);
    if (_selectedId == id) _selectedId = null;
    notifyListeners();
  }

  void updatePosition(String id, double x, double y) {
    final index = _elements.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _elements[index] = _elements[index].copyWithPosition(x, y);
    notifyListeners();
  }

  void updateElement(CanvasElement updated) {
    final index = _elements.indexWhere((e) => e.id == updated.id);
    if (index == -1) return;
    _elements[index] = updated;
    notifyListeners();
  }

  void selectElement(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  void bringToFront(String id) {
    final index = _elements.indexWhere((e) => e.id == id);
    if (index == -1 || index == _elements.length - 1) return;
    final element = _elements.removeAt(index);
    _elements.add(element);
    notifyListeners();
  }

  void clear() {
    _elements.clear();
    _selectedId = null;
    notifyListeners();
  }
}
