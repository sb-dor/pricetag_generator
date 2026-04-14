import 'receipt_item.dart';

class Receipt {
  final String storeName;
  final List<ReceiptItem> items;
  final DateTime printedAt;

  const Receipt({
    required this.storeName,
    required this.items,
    required this.printedAt,
  });

  double get subtotal => items.fold(0.0, (s, i) => s + i.lineSubtotal);
  double get totalDiscount => items.fold(0.0, (s, i) => s + i.lineDiscount);
  double get total => subtotal - totalDiscount;
  bool get hasDiscount => totalDiscount > 0;
  bool get isEmpty => items.isEmpty;
}
