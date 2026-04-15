import 'package:flutter/foundation.dart';

import '../../catalog/models/product.dart';
import '../../template/models/receipt_template.dart';
import '../models/receipt.dart';
import '../models/receipt_item.dart';

class ReceiptNotifier extends ChangeNotifier {
  ReceiptTemplate _template = ReceiptTemplate.defaultTemplate;
  final List<ReceiptItem> _items = [];

  ReceiptTemplate get template => _template;
  List<ReceiptItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.fold(0.0, (s, i) => s + i.lineSubtotal);
  double get totalDiscount => _items.fold(0.0, (s, i) => s + i.lineDiscount);
  double get total => subtotal - totalDiscount;
  bool get hasDiscount => totalDiscount > 0;

  void setTemplate(ReceiptTemplate t) {
    _template = t;
    notifyListeners();
  }

  void addProduct(Product product) {
    // If product already exists, increment qty
    final i = _items.indexWhere((item) => item.id == product.id);
    if (i != -1) {
      _items[i] = _items[i].copyWith(qty: _items[i].qty + 1);
    } else {
      _items.add(
        ReceiptItem(
          id: product.id,
          label: product.name,
          unit: product.unit,
          price: product.price,
          qty: 1,
        ),
      );
    }
    notifyListeners();
  }

  void updateItem(int index, ReceiptItem updated) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = updated;
    notifyListeners();
  }

  void removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Receipt buildReceipt(String storeName) => Receipt(
    storeName: storeName,
    items: List.of(_items),
    printedAt: DateTime.now(),
    customerCode: '777888999',
    customerName: 'Nuqr',
    previousDebt: 90,
  );
}
